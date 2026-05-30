import { Circle, Icon, Layout, Rect, makeScene2D } from "@motion-canvas/2d";
import { all, createRef, easeOutQuad, waitFor } from "@motion-canvas/core";

export default makeScene2D(function* (view) {
	const tileSource = createRef<Rect>();
	view.add(<Rect ref={tileSource} size={[200, 200]} fill={"#acd7ff"} radius={40} />);

	const tileNew = createRef<Rect>();
	view.add(<Rect ref={tileNew} size={[200, 200]} fill={"#ffe3b5"} radius={40} opacity={0} />);

	const cursor = createRef<Icon>();
	view.add(
		<Icon
			ref={cursor}
			icon={"iconamoon:cursor-fill"}
			size={60}
			shadowColor={"#00000066"}
			shadowBlur={10}
			position={[300, 30]}
			offset={[-1, -1]}
		/>,
	);

	const arrow = createRef<Icon>();
	cursor().add(
		<Icon
			ref={arrow}
			icon={"material-symbols:keyboard-arrow-up-rounded"}
			size={100}
			shadowColor={"#00000033"}
			shadowBlur={10}
			opacity={0}
		/>,
	);

	yield* cursor().position(tileSource().position().add([-30, -30]), 0.7);

	function* swipeTile(source: Rect, target: Rect, sourceColor: string, targetColor: string) {
		source.fill(sourceColor);
		target.fill(targetColor);
		target.opacity(0);
		arrow().position.y(0);
		arrow().scale(0.5);

		yield* waitFor(0.3);

		yield* all(
			arrow().position.y(-70, 0.5),
			arrow().opacity(1, 0.3),
			arrow().scale(1.3, 0.5),
			target.opacity(1, 0.3),
		);

		yield* arrow().opacity(0, 0.3);
		yield* waitFor(0.1);
	}

	yield* swipeTile(tileSource(), tileNew(), "#acd7ff", "#90ed90");
	yield* swipeTile(tileSource(), tileNew(), "#90ed90", "#ff80ff");
	yield* swipeTile(tileSource(), tileNew(), "#ff80ff", "#ffe3b5");
	yield* waitFor(0.8);
});
