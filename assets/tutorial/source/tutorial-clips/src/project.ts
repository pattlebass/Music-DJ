import { makeProject } from "@motion-canvas/core";

import tile_long_press from "./scenes/tile_long_press?scene";
import tile_quick_edit_swipe from "./scenes/tile_quick_edit_swipe?scene";
import tile_quick_edit_scroll from "./scenes/tile_quick_edit_scroll?scene";
import tile_context_menu from "./scenes/tile_context_menu?scene";
import column_button from "./scenes/column_button?scene";
import column_move from "./scenes/column_move?scene";

export default makeProject({
	scenes: [tile_quick_edit_scroll],
});
