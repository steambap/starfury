import 'package:flame/components.dart';

import "sim_props.dart";
import "scifi_game.dart";
import "sector.dart";
import "async_updated_ui.dart";
import "styles.dart";
import "components/row_container.dart";

class HudSectorInfo extends PositionComponent
    with HasGameRef<ScifiGame>, HasVisibility, AsyncUpdatedUi {
      static final panelTitleSize = Vector2(160, 24);
      static final panelBodySize = Vector2(160, 72);

  late Sector sector;

  final _titleBackground = RectangleComponent(size: panelTitleSize, paint: panelTitleBG);
  final _sectorName = TextComponent(
      textRenderer: label16, anchor: Anchor.centerLeft, position: Vector2(4, panelTitleSize.y / 2));

  final _bodyBackground = RectangleComponent(size: panelBodySize, paintLayers: panelSkin);
  final RowContainer _resourceRow = RowContainer(size: Vector2.zero(), position: Vector2(4, 40));

  final TextComponent _productionIcon =
      TextComponent(text: "\u4a95", textRenderer: icon16red);
  final _productionLabel = TextComponent(text: "0", textRenderer: text12);

  final TextComponent _creditIcon =
      TextComponent(text: "\u3fde", textRenderer: icon16yellow);
  final _creditLabel = TextComponent(text: "0", textRenderer: text12);

  final TextComponent _scienceIcon =
      TextComponent(text: "\u48bb", textRenderer: icon16blue);
  final _scienceLabel = TextComponent(text: "0", textRenderer: text12);

  HudSectorInfo();

  @override
  Future<void> onLoad() async {
    isVisible = false;

    _resourceRow.addAll([
      _productionIcon,
      _productionLabel,
      _creditIcon,
      _creditLabel,
      _scienceIcon,
      _scienceLabel,
    ]);

    addAll([
      _bodyBackground,
      _titleBackground,
      _sectorName,
      _resourceRow,
    ]);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    position = Vector2(size.x - 124 - panelTitleSize.x, size.y - panelBodySize.y - 8);
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    if (isVisible) {
      return super.containsLocalPoint(point);
    }

    return false;
  }

  void hide() {
    isVisible = false;
  }

  void show(Sector sector) {
    isVisible = true;
    _setText(sector);
  }

  @override
  void updateRender() {
    _setText(sector);
  }

  void _setText(Sector sector) {
    _sectorName.text = sector.displayName;
    _productionLabel.text = "+${sector.getProp(SimProps.production)}";
    _creditLabel.text = "+${sector.getProp(SimProps.credit)}";
    _scienceLabel.text = "+${sector.getProp(SimProps.science)}";

    _resourceRow.layout();
  }
}
