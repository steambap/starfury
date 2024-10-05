import "package:flame/components.dart";

import "styles.dart";
import "scifi_game.dart";
import "components/advanced_button.dart";
import "side_menu_overlay.dart";

class HudMenuButton extends AdvancedButton with HasGameRef<ScifiGame> {
  HudMenuButton()
      : super(
          size: primarySize,
          defaultLabel: TextComponent(
              text: "MENU", textRenderer: heading20),
          hoverLabel: TextComponent(
              text: "MENU",
              textRenderer: heading20DarkGray),
          defaultSkin: RectangleComponent(paint: btnDefault),
          hoverSkin: RectangleComponent(paint: btnHover),
        );

  @override
  Future<void> onLoad() {
    onReleased = () {
      game.router.pushRoute(SideMenuOverlay());
    };
    return super.onLoad();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x - primarySize.x - 8, size.y - primarySize.y - 8);
  }
}