import 'package:zedu/core/core.dart';

class AuthHeaderStrip extends StatelessWidget {
  const AuthHeaderStrip({
    super.key,
    this.promptText,
    this.actionText,
    this.onActionTap,
  });

  final String? promptText;
  final String? actionText;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: context.symmetric(horizontal: 68, vertical: 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/pngs/zedu_logo.png', width: 83, height: 31),
            if (promptText != null && actionText != null)
              Row(
                children: [
                  Text(
                    promptText!,
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: context.colors.textPrimary,
                      fontFamily: FontFamily.roboto,
                    ),
                  ),
                  InkWell(
                    onTap: onActionTap,
                    child: Text(
                      actionText!,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: context.colors.primary,
                        fontFamily: FontFamily.roboto,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
