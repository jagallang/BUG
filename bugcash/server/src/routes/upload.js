const express = require('express');
const multer = require('multer');
const admin = require('firebase-admin');
const AWS = require('aws-sdk');
const sharp = require('sharp');
const path = require('path');
const crypto = require('crypto');

const router = express.Router();

// Configure AWS S3
const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION || 'ap-northeast-2'
});

// Configure multer for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 300 * 1024 * 1024, // 300MB limit for APK files
  },
  fileFilter: (req, file, cb) => {
    // Allow APK files, images, and documents
    const allowedTypes = [
      'application/vnd.android.package-archive', // APK
      'application/octet-stream', // APK (alternative MIME type)
      'image/jpeg',
      'image/png',
      'image/webp',
      'application/pdf',
      'text/plain'
    ];
    
    if (allowedTypes.includes(file.mimetype) || file.originalname.endsWith('.apk')) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type'), false);
    }
  }
});

// APK 파일 업로드 엔드포인트
router.post('/apk', upload.single('apk'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No APK file provided' });
    }

    const { providerId, appName, appVersion } = req.body;
    if (!providerId || !appName) {
      return res.status(400).json({ error: 'Provider ID and app name are required' });
    }

    // Generate unique filename
    const fileId = crypto.randomUUID();
    const fileName = `apk/${providerId}/${fileId}_${appName.replace(/[^a-zA-Z0-9]/g, '_')}.apk`;

    let downloadUrl;
    
    // Development mode - simulate upload without AWS
    if (process.env.NODE_ENV === 'development') {
      // Simulate successful upload
      downloadUrl = `http://localhost:${process.env.PORT || 3002}/api/upload/download/${fileId}`;
      console.log(`📁 [DEV] Mock APK uploaded: ${fileName} (${req.file.size} bytes)`);
    } else {
      // Production mode - use real AWS S3
      const uploadParams = {
        Bucket: process.env.AWS_S3_BUCKET || 'bugcash-files',
        Key: fileName,
        Body: req.file.buffer,
        ContentType: 'application/vnd.android.package-archive',
        Metadata: {
          'provider-id': providerId,
          'app-name': appName,
          'app-version': appVersion || '1.0.0',
          'upload-timestamp': new Date().toISOString()
        }
      };

      const uploadResult = await s3.upload(uploadParams).promise();

      // Generate signed URL for download (valid for 24 hours)
      downloadUrl = s3.getSignedUrl('getObject', {
        Bucket: uploadParams.Bucket,
        Key: fileName,
        Expires: 24 * 60 * 60 // 24 hours
      });
    }

    // Save file info to Firestore (development mode uses mock data)
    const fileInfo = {
      fileId,
      providerId,
      appName,
      appVersion: appVersion || '1.0.0',
      fileName: req.file.originalname,
      filePath: fileName,
      fileSize: req.file.size,
      downloadUrl,
      uploadedAt: process.env.NODE_ENV === 'development' ? new Date() : admin.firestore.FieldValue.serverTimestamp(),
      downloadCount: 0,
      status: 'active'
    };

    if (process.env.NODE_ENV === 'development') {
      // Development mode - store in memory or log instead of Firestore
      console.log(`📄 [DEV] Mock file info stored:`, fileInfo);
    } else {
      // Production mode - use real Firestore
      await admin.firestore()
        .collection('uploaded_files')
        .doc(fileId)
        .set(fileInfo);
    }

    res.json({
      success: true,
      fileId,
      downloadUrl,
      fileName: req.file.originalname,
      fileSize: req.file.size
    });

  } catch (error) {
    console.error('APK upload error:', error);
    res.status(500).json({ error: 'Failed to upload APK file' });
  }
});

// 이미지 업로드 엔드포인트 (앱 스크린샷, 아이콘 등)
router.post('/image', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file provided' });
    }

    const { providerId, appId, imageType } = req.body; // imageType: 'icon', 'screenshot', 'banner'
    
    let processedImage;
    let publicUrl;
    const fileId = crypto.randomUUID();
    const fileName = `images/${providerId}/${appId || 'general'}/${imageType}/${fileId}.${imageType === 'icon' ? 'png' : 'jpg'}`;
    
    if (process.env.NODE_ENV === 'development') {
      // Development mode - skip image processing
      processedImage = req.file.buffer;
      publicUrl = `http://localhost:${process.env.PORT || 3003}/api/upload/image/${fileId}`;
      console.log(`🖼️ [DEV] Mock image uploaded: ${fileName} (${req.file.size} bytes, type: ${imageType})`);
    } else {
      // Production mode - optimize image with Sharp
      if (imageType === 'icon') {
        // App icons - resize to 512x512
        processedImage = await sharp(req.file.buffer)
          .resize(512, 512, { fit: 'inside', withoutEnlargement: true })
          .png({ quality: 90 })
          .toBuffer();
      } else if (imageType === 'screenshot') {
        // Screenshots - optimize but maintain aspect ratio
        processedImage = await sharp(req.file.buffer)
          .resize(1080, 1920, { fit: 'inside', withoutEnlargement: true })
          .jpeg({ quality: 80 })
          .toBuffer();
      } else {
        // Other images - general optimization
        processedImage = await sharp(req.file.buffer)
          .resize(1200, 1200, { fit: 'inside', withoutEnlargement: true })
          .jpeg({ quality: 85 })
          .toBuffer();
      }
    }

    // Upload to S3 (production only)
    if (process.env.NODE_ENV !== 'development') {
      const uploadParams = {
        Bucket: process.env.AWS_S3_BUCKET || 'bugcash-files',
        Key: fileName,
        Body: processedImage,
        ContentType: imageType === 'icon' ? 'image/png' : 'image/jpeg',
        CacheControl: 'public, max-age=31536000', // Cache for 1 year
        Metadata: {
          'provider-id': providerId,
          'app-id': appId || '',
          'image-type': imageType,
          'original-name': req.file.originalname
        }
      };

      const uploadResult = await s3.upload(uploadParams).promise();

      // Make image publicly accessible
      publicUrl = `https://${process.env.AWS_S3_BUCKET}.s3.${process.env.AWS_REGION}.amazonaws.com/${fileName}`;
    }

    // Save image info to Firestore (development mode uses mock data)
    const imageInfo = {
      fileId,
      providerId,
      appId: appId || null,
      imageType,
      fileName: req.file.originalname,
      filePath: fileName,
      publicUrl,
      fileSize: processedImage.length,
      uploadedAt: process.env.NODE_ENV === 'development' ? new Date() : admin.firestore.FieldValue.serverTimestamp(),
      status: 'active'
    };

    if (process.env.NODE_ENV === 'development') {
      // Development mode - store in memory or log instead of Firestore
      console.log(`📷 [DEV] Mock image info stored:`, imageInfo);
    } else {
      // Production mode - use real Firestore
      await admin.firestore()
        .collection('uploaded_images')
        .doc(fileId)
        .set(imageInfo);
    }

    res.json({
      success: true,
      fileId,
      publicUrl,
      fileName: req.file.originalname,
      optimizedSize: processedImage.length
    });

  } catch (error) {
    console.error('Image upload error:', error);
    res.status(500).json({ error: 'Failed to upload image' });
  }
});

// 파일 다운로드 추적
router.get('/download/:fileId', async (req, res) => {
  try {
    const { fileId } = req.params;
    
    // Get file info from Firestore
    const fileDoc = await admin.firestore()
      .collection('uploaded_files')
      .doc(fileId)
      .get();

    if (!fileDoc.exists) {
      return res.status(404).json({ error: 'File not found' });
    }

    const fileData = fileDoc.data();
    
    // Increment download count
    await fileDoc.ref.update({
      downloadCount: admin.firestore.FieldValue.increment(1),
      lastDownloadedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Generate fresh signed URL if needed
    const downloadUrl = s3.getSignedUrl('getObject', {
      Bucket: process.env.AWS_S3_BUCKET || 'bugcash-files',
      Key: fileData.filePath,
      Expires: 60 * 60, // 1 hour
      ResponseContentDisposition: `attachment; filename="${fileData.fileName}"`
    });

    res.json({
      success: true,
      downloadUrl,
      fileName: fileData.fileName,
      fileSize: fileData.fileSize
    });

  } catch (error) {
    console.error('Download tracking error:', error);
    res.status(500).json({ error: 'Failed to generate download URL' });
  }
});

// 파일 삭제
router.delete('/:fileId', async (req, res) => {
  try {
    const { fileId } = req.params;
    const { providerId } = req.body;

    // Get file info
    const fileDoc = await admin.firestore()
      .collection('uploaded_files')
      .doc(fileId)
      .get();

    if (!fileDoc.exists) {
      return res.status(404).json({ error: 'File not found' });
    }

    const fileData = fileDoc.data();
    
    // Verify ownership
    if (fileData.providerId !== providerId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    // Delete from S3
    await s3.deleteObject({
      Bucket: process.env.AWS_S3_BUCKET || 'bugcash-files',
      Key: fileData.filePath
    }).promise();

    // Mark as deleted in Firestore
    await fileDoc.ref.update({
      status: 'deleted',
      deletedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    res.json({ success: true });

  } catch (error) {
    console.error('File deletion error:', error);
    res.status(500).json({ error: 'Failed to delete file' });
  }
});

module.exports = router;