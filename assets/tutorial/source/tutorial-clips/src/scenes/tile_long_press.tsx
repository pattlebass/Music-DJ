import { Circle, Layout, Rect, makeScene2D } from "@motion-canvas/2d";
import { all, createRef, waitFor } from "@motion-canvas/core";

export default makeScene2D(function* (view) {
	const tileSource = createRef<Rect>();
	view.add(
		<Rect ref={tileSource} size={[200, 200]} fill={"#fa85fa"} position={[-150, 0]} radius={40} />,
	);

	const tileDest = createRef<Rect>();
	view.add(
		<Rect ref={tileDest} size={[200, 200]} position={[150, 0]} fill={"#4ecca3"} radius={40} />,
	);

	yield* waitFor(0.3);

	const fingertip = createRef<Layout>();
	view.add(<Layout ref={fingertip} position={tileSource().position()} />);

	const circle = createRef<Circle>();
	fingertip().add(
		<Circle
			ref={circle}
			size={60}
			scale={0}
			fill={"#fff"}
			shadowColor={"#00000066"}
			shadowBlur={10}
		/>,
	);

	yield* circle().scale(1, 0.3);
	yield* waitFor(0.3);

	const tileFloating = createRef<Rect>();
	fingertip().insert(
		<Rect ref={tileFloating} size={[200, 200]} fill={"#fa85fa"} radius={40} shadowColor={"#000"} />,
		0,
	);

	yield* all(tileFloating().scale(1.2, 0.3), tileFloating().shadowBlur(20, 0.3));

	yield* waitFor(0.3);

	yield* fingertip().position(tileDest().position(), 1);

	yield* waitFor(0.3);

	yield* all(
		tileFloating().scale(1, 0.3),
		tileFloating().shadowBlur(0, 0.3),

		circle().scale(0, 0.3),
	);

	tileDest().fill(tileFloating().fill());
	fingertip().remove();

	yield* waitFor(0.6);
});
