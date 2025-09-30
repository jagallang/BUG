import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/responsive_data_provider.dart';

/// ResponsiveData를 제공하는 Builder 위젯
/// MediaQuery 호출을 최적화하고 ResponsiveData를 Provider로 제공
class ResponsiveBuilder extends ConsumerWidget {
  final Widget Function(BuildContext context, ResponsiveData responsive) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final responsiveData = ref.watch(responsiveDataProvider(screenSize));

    // ResponsiveData를 하위 위젯에서 사용할 수 있도록 Provider로 제공
    return ProviderScope(
      overrides: [
        contextResponsiveDataProvider.overrideWithValue(responsiveData),
      ],
      child: builder(context, responsiveData),
    );
  }
}

/// ResponsiveData에 쉽게 접근할 수 있는 Consumer 위젯
class ResponsiveConsumer extends ConsumerWidget {
  final Widget Function(BuildContext context, WidgetRef ref, ResponsiveData responsive) builder;

  const ResponsiveConsumer({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsiveData = ref.watch(contextResponsiveDataProvider);

    // ResponsiveData가 없다면 MediaQuery로 직접 생성
    if (responsiveData == null) {
      final screenSize = MediaQuery.of(context).size;
      final data = ref.watch(responsiveDataProvider(screenSize));
      return builder(context, ref, data);
    }

    return builder(context, ref, responsiveData);
  }
}

/// BuildContext extension for easy ResponsiveData access
extension ResponsiveContext on BuildContext {
  /// ResponsiveData에 직접 접근 (Consumer 위젯 내에서 사용)
  ResponsiveData? get responsive {
    try {
      return ProviderScope.containerOf(this).read(contextResponsiveDataProvider);
    } catch (e) {
      return null;
    }
  }
}

/// WidgetRef extension for easy ResponsiveData access
extension ResponsiveRef on WidgetRef {
  /// ResponsiveData에 직접 접근
  ResponsiveData? get responsive {
    return read(contextResponsiveDataProvider);
  }

  /// 현재 화면 크기로 ResponsiveData 생성
  ResponsiveData responsiveFromContext(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return read(responsiveDataProvider(screenSize));
  }
}