import { Circle, Icon, Layout, Rect, makeScene2D } from "@motion-canvas/2d";
import { all, any, createRef, waitFor } from "@motion-canvas/core";

export default makeScene2D(function* (view) {
	const tileSource = createRef<Rect>();
	view.add(<Rect ref={tileSource} size={[200, 200]} fill={"#ff80ff"} radius={40} zIndex={-5} />);

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

	yield* cursor().position(tileSource().position().add([-30, -30]), 0.7);

	yield* waitFor(0.5);

	yield* all(cursor().scale(0.8, 0.2), cursor().rotation(10, 0.2));
	yield* all(cursor().scale(1, 0.2), cursor().rotation(0, 0.2));

	const contextMenu = createRef<Rect>();
	view.add(
		<Rect
			ref={contextMenu}
			size={[250, 250]}
			fill={"#393e46"}
			radius={20}
			topLeft={cursor().position().add([28, 20])}
			opacity={0}
			scale={[0.3, 0.3]}
			offset={[-1, -1]}
			zIndex={-1}
		/>,
	);

	yield* any(
		contextMenu().opacity(1, 0.1),
		contextMenu().position.y(contextMenu().position().y + 10, 0.3),
		contextMenu().scale(1, 0.2),
	);

	yield* waitFor(1);
	yield* cursor().position([300, 30], 1);
	yield* contextMenu().opacity(0, 0.2);

	yield* waitFor(1);
});
