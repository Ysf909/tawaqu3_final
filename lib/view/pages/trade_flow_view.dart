import 'package:flutter/material.dart';
import 'package:tawaqu3_final/view/pages/trade_tab_page.dart';
import 'package:tawaqu3_final/view/widgets/primary_button.dart';
import 'trade_model_page.dart';
import 'trade_margin_page.dart';
import 'trade_result_page.dart';

class TradeFlowView extends StatefulWidget {
  const TradeFlowView({super.key});

  @override
  State<TradeFlowView> createState() => _TradeFlowViewState();
}

class _TradeFlowViewState extends State<TradeFlowView> {
  late final PageController _pageController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int index) {
    setState(() => _currentStep = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _goToStep(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade Generation Flow'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          return Column(
            children: [
              // STEP HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _StepHeader(
                  currentStep: _currentStep,
                  onStepTap: _goToStep,
                ),
              ),

              const Divider(height: 1),

              // PAGE AREA
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: PageView(
                      controller: _pageController,
                      physics: isWide
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _currentStep = index);
                      },
                      children: const [
                        TradeTypePage(),
                        TradeModelPage(),
                        TradeMarginPage(),
                        TradeResultPage(),
                      ],
                    ),
                  ),
                ),
              ),

              // BOTTOM NAVIGATION
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: _previousStep,
                        child: const Text('BACK'),
                      )
                    else
                      const SizedBox(width: 80),
                    const Spacer(),
                    PrimaryButton(
                      label: _currentStep == 3 ? 'DONE' : 'NEXT',
                      loading: false,
                      onPressed: _nextStep,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int currentStep;
  final void Function(int index) onStepTap;

  const _StepHeader({required this.currentStep, required this.onStepTap});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Type', Icons.timeline),
      ('Model', Icons.auto_fix_high),
      ('Risk', Icons.shield),
      ('Result', Icons.assessment),
    ];

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final isActive = index == currentStep;
        final isDone = index < currentStep;

        final bgColor = isActive
            ? colorScheme.primary
            : isDone
            ? colorScheme.primary.withOpacity(0.15)
            : colorScheme.surfaceContainerHighest;
        final fgColor = isActive
            ? colorScheme.onPrimary
            : isDone
            ? colorScheme.primary
            : theme.textTheme.bodyMedium?.color;

        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onStepTap(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(steps[index].$2, size: 18, color: fgColor),
                      const SizedBox(width: 6),
                      Text(
                        steps[index].$1,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: fgColor,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
