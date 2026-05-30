import { Circle, Layout, Rect, makeScene2D } from "@motion-canvas/2d";
import { all, createRef, waitFor } from "@motion-canvas/core";

export default makeScene2D(function* (view) {
	const tileSource = createRef<Rect>();
	view.add(<Rect ref={tileSource} size={[200, 200]} fill={"#ff80ff"} radius={40} />);

	const tileNew = createRef<Rect>();
	view.add(<Rect ref={tileNew} size={[200, 200]} fill={"#ffe3b5"} radius={40} opacity={0} />);

	const circle = createRef<Circle>();
	view.add(
		<Circle
			ref={circle}
			size={60}
			scale={0}
			fill={"#fff"}
			shadowColor={"#00000066"}
			shadowBlur={10}
		/>,
	);

	function* swipeTile(source: Rect, target: Rect, sourceColor: string, targetColor: string) {
		source.fill(sourceColor);
		target.fill(targetColor);
		target.opacity(0);
		circle().position.y(-100);

		yield* waitFor(0.3);
		yield* circle().scale(1, 0.3);

		yield* all(circle().position.y(100, 0.5), target.opacity(1, 0.3));

		yield* circle().scale(0, 0.3);
		yield* waitFor(0.1);
	}

	yield* swipeTile(tileSource(), tileNew(), "#acd7ff", "#90ed90");
	yield* swipeTile(tileSource(), tileNew(), "#90ed90", "#ff80ff");
	yield* swipeTile(tileSource(), tileNew(), "#ff80ff", "#ffe3b5");
	yield* waitFor(0.8);
});
