import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// v2.103.0: 관리자 대시보드 - 에스크로 관리 탭
///
/// 에스크로 시스템의 전체 현황을 조회하고 관리하는 독립 탭
/// - 에스크로 보관 금액 총계
/// - 앱별 에스크로 내역 (공급자, 보관금액, 사용금액, 잔액)
/// - 에스크로 거래 내역 (입금/지급/환불)
/// - 날짜별/앱별/공급자별 검색
class EscrowManagementTab extends StatefulWidget {
  const EscrowManagementTab({super.key});

  @override
  State<EscrowManagementTab> createState() => _EscrowManagementTabState();
}

class _EscrowManagementTabState extends State<EscrowManagementTab> {
  // 검색 필터 상태
  String _escrowKeyword = ''; // 앱 이름 검색
  String _escrowProviderEmail = ''; // 공급자 이메일 검색
  DateTime? _escrowStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime? _escrowEndDate = DateTime.now();
  String _escrowStatus = 'all'; // all, active, completed, refunded

  // 검색 필터 컨트롤러
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _providerEmailController = TextEditingController();

  @override
  void dispose() {
    _keywordController.dispose();
    _providerEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          const Text(
            'Escrow - 에스크로 관리',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '앱 등록 시 예치된 포인트를 안전하게 보관하고 관리합니다',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // 에스크로 요약 카드
          _buildEscrowSummaryCards(),
          const SizedBox(height: 32),

          // 검색 필터
          _buildEscrowFilters(),
          const SizedBox(height: 24),

          // 에스크로 홀딩 테이블
          _buildEscrowHoldingsTable(),
        ],
      ),
    );
  }

  /// 에스크로 요약 카드 (4개)
  Widget _buildEscrowSummaryCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('escrow_holdings')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('에러: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // 데이터 집계
        int activeCount = 0;
        int totalAmount = 0;
        int remainingAmount = 0;
        int spentAmount = 0;
        int refundedAmount = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String?;

          if (status == 'active') {
            activeCount++;
            remainingAmount += (data['remainingAmount'] ?? 0) as int;
          }

          totalAmount += (data['totalAmount'] ?? 0) as int;
          spentAmount += (data['spentAmount'] ?? 0) as int;

          if (status == 'refunded') {
            // 환불된 건의 원래 잔액 (환불 시점 remainingAmount)
            refundedAmount += ((data['totalAmount'] ?? 0) as int) - ((data['spentAmount'] ?? 0) as int);
          }
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildSummaryCard(
              '총 보관액',
              '${_formatAmount(remainingAmount)}P',
              Colors.teal,
              Icons.account_balance_wallet,
              '현재 에스크로 계정에 보관중인 금액',
            ),
            _buildSummaryCard(
              '활성 앱',
              '$activeCount개',
              Colors.green,
              Icons.app_registration,
              '에스크로가 활성 상태인 앱 수',
            ),
            _buildSummaryCard(
              '총 지급액',
              '${_formatAmount(spentAmount)}P',
              Colors.orange,
              Icons.payments,
              '테스터에게 지급 완료된 총 금액',
            ),
            _buildSummaryCard(
              '환불액',
              '${_formatAmount(refundedAmount)}P',
              Colors.purple,
              Icons.replay,
              '공급자에게 환불된 총 금액',
            ),
          ],
        );
      },
    );
  }

  /// 요약 카드 (개별)
  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const Spacer(),
                Icon(Icons.info_outline, size: 16, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 검색 필터 UI
  Widget _buildEscrowFilters() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.filter_list, size: 20),
                SizedBox(width: 8),
                Text(
                  '검색 필터',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                // 날짜 범위
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('시작일', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(_escrowStartDate == null
                                  ? '선택 안함'
                                  : DateFormat('yyyy-MM-dd').format(_escrowStartDate!)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('종료일', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(_escrowEndDate == null
                                  ? '선택 안함'
                                  : DateFormat('yyyy-MM-dd').format(_escrowEndDate!)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 앱 이름 검색
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('앱 이름', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _keywordController,
                        decoration: const InputDecoration(
                          hintText: '앱 이름 검색',
                          prefixIcon: Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _escrowKeyword = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // 공급자 이메일 검색
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('공급자 이메일', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _providerEmailController,
                        decoration: const InputDecoration(
                          hintText: '이메일 검색',
                          prefixIcon: Icon(Icons.email, size: 20),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _escrowProviderEmail = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // 상태 필터
                SizedBox(
                  width: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('상태', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: _escrowStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('전체')),
                          DropdownMenuItem(value: 'active', child: Text('활성')),
                          DropdownMenuItem(value: 'completed', child: Text('완료')),
                          DropdownMenuItem(value: 'refunded', child: Text('환불')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _escrowStatus = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 버튼들
            ElevatedButton.icon(
              onPressed: () {
                setState(() {}); // 필터 적용 (StreamBuilder가 자동 갱신)
              },
              icon: const Icon(Icons.search, size: 18),
              label: const Text('검색'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('초기화'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
            ),
          ),
        ),
      ),
    );
  }

  /// 날짜 선택 다이얼로그
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_escrowStartDate ?? DateTime.now())
          : (_escrowEndDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _escrowStartDate = picked;
        } else {
          _escrowEndDate = picked;
        }
      });
    }
  }

  /// 필터 초기화
  void _resetFilters() {
    setState(() {
      _escrowKeyword = '';
      _escrowProviderEmail = '';
      _escrowStartDate = DateTime.now().subtract(const Duration(days: 30));
      _escrowEndDate = DateTime.now();
      _escrowStatus = 'all';
      _keywordController.clear();
      _providerEmailController.clear();
    });
  }

  /// 에스크로 홀딩 테이블
  Widget _buildEscrowHoldingsTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('escrow_holdings')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('에러: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // 클라이언트 사이드 필터링
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // 날짜 필터
          if (_escrowStartDate != null) {
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            if (createdAt == null || createdAt.isBefore(_escrowStartDate!)) {
              return false;
            }
          }
          if (_escrowEndDate != null) {
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            if (createdAt == null || createdAt.isAfter(_escrowEndDate!.add(const Duration(days: 1)))) {
              return false;
            }
          }

          // 앱 이름 검색
          if (_escrowKeyword.isNotEmpty) {
            final appName = (data['appName'] ?? '').toLowerCase();
            if (!appName.contains(_escrowKeyword.toLowerCase())) {
              return false;
            }
          }

          // 공급자 이메일 검색
          if (_escrowProviderEmail.isNotEmpty) {
            final providerId = (data['providerId'] ?? '').toLowerCase();
            if (!providerId.contains(_escrowProviderEmail.toLowerCase())) {
              return false;
            }
          }

          // 상태 필터
          if (_escrowStatus != 'all') {
            if (data['status'] != _escrowStatus) {
              return false;
            }
          }

          return true;
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      '검색 결과가 없습니다',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Card(
          elevation: 2,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
              columns: const [
                DataColumn(label: Text('앱 이름', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('공급자', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('예치일', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('총액', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('사용액', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('잔액', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('상태', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('작업', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: filteredDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DataRow(cells: [
                  DataCell(
                    Text(
                      data['appName'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          data['providerName'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          data['providerId'] ?? '-',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(_formatDate(data['depositedAt']))),
                  DataCell(Text('${_formatAmount(data['totalAmount'])}P')),
                  DataCell(Text(
                    '${_formatAmount(data['spentAmount'])}P',
                    style: const TextStyle(color: Colors.orange),
                  )),
                  DataCell(Text(
                    '${_formatAmount(data['remainingAmount'])}P',
                    style: TextStyle(
                      color: (data['remainingAmount'] ?? 0) > 0 ? Colors.teal : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
                  DataCell(_buildStatusBadge(data['status'])),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.teal),
                      tooltip: '상세보기',
                      onPressed: () => _showEscrowDetailDialog(data),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  /// 상태 배지
  Widget _buildStatusBadge(String? status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'active':
        color = Colors.green;
        label = '활성';
        icon = Icons.check_circle;
        break;
      case 'completed':
        color = Colors.blue;
        label = '완료';
        icon = Icons.done_all;
        break;
      case 'refunded':
        color = Colors.purple;
        label = '환불';
        icon = Icons.replay;
        break;
      default:
        color = Colors.grey;
        label = '알 수 없음';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 에스크로 상세 모달
  void _showEscrowDetailDialog(Map<String, dynamic> escrowData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 700,
          constraints: const BoxConstraints(maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  const Icon(Icons.account_balance, color: Colors.teal, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${escrowData['appName'] ?? '알 수 없는 앱'} 에스크로 상세',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),

              // 기본 정보
              _buildInfoSection('📊 기본 정보', [
                _buildInfoRow('공급자', '${escrowData['providerName']} (${escrowData['providerId']})'),
                _buildInfoRow('예치일', _formatDateTime(escrowData['depositedAt'])),
                _buildInfoRow('상태', '', widget: _buildStatusBadge(escrowData['status'])),
              ]),
              const SizedBox(height: 20),

              // 금액 정보
              _buildInfoSection('💰 금액 정보', [
                _buildInfoRow('총 예치액', '${_formatAmount(escrowData['totalAmount'])}P',
                    color: Colors.teal),
                _buildInfoRow('지급 완료', '${_formatAmount(escrowData['spentAmount'])}P',
                    color: Colors.orange),
                _buildInfoRow('잔액', '${_formatAmount(escrowData['remainingAmount'])}P',
                    color: Colors.green, bold: true),
              ]),
              const SizedBox(height: 20),

              // 거래 내역
              Expanded(
                child: _buildTransactionsList(escrowData['transactions']),
              ),

              const SizedBox(height: 20),

              // 닫기 버튼
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 정보 섹션
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  /// 정보 행
  Widget _buildInfoRow(String label, String value, {Color? color, bool bold = false, Widget? widget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          if (widget != null)
            widget
          else
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 거래 내역 리스트
  Widget _buildTransactionsList(dynamic transactions) {
    final List<dynamic> txList = transactions is List ? transactions : [];

    if (txList.isEmpty) {
      return const Center(
        child: Text(
          '거래 내역이 없습니다',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📜 거래 내역',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: txList.length,
            itemBuilder: (context, index) {
              final tx = txList[index] as Map<String, dynamic>;
              final type = tx['type'] as String?;
              Color iconColor;
              IconData icon;
              String typeLabel;

              switch (type) {
                case 'deposit':
                  iconColor = Colors.blue;
                  icon = Icons.arrow_downward;
                  typeLabel = '예치';
                  break;
                case 'payout':
                  iconColor = Colors.green;
                  icon = Icons.arrow_upward;
                  typeLabel = '지급';
                  break;
                case 'refund':
                  iconColor = Colors.purple;
                  icon = Icons.replay;
                  typeLabel = '환불';
                  break;
                default:
                  iconColor = Colors.grey;
                  icon = Icons.circle;
                  typeLabel = '알 수 없음';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: iconColor.withOpacity(0.1),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  title: Row(
                    children: [
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatAmount(tx['amount'])}P',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        _formatDateTime(tx['createdAt']),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('${tx['from'] ?? '-'} → ${tx['to'] ?? '-'}'),
                      if (tx['description'] != null)
                        Text(
                          tx['description'],
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 금액 포맷 (천 단위 콤마)
  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final formatter = NumberFormat('#,###');
    return formatter.format(amount);
  }

  /// 날짜 포맷 (YYYY-MM-DD)
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '-';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('yyyy-MM-dd').format(date);
    }
    return '-';
  }

  /// 날짜시간 포맷 (YYYY-MM-DD HH:mm)
  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return '-';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    }
    return '-';
  }
}
