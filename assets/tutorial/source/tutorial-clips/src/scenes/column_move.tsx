import { Layout, Rect, makeScene2D } from "@motion-canvas/2d";
import { all, createRef, easeInOutSine, Reference, waitFor } from "@motion-canvas/core";

export default makeScene2D(function* (view) {
	const columnLeft = createRef<Layout>();
	const columnRight = createRef<Layout>();
	const movingColumn = createRef<Layout>();
	const movingColumnButton = createRef<Rect>();

	view.add(createColumn(columnLeft));
	columnLeft().position.x(-112);
	view.add(createColumn(columnRight));
	columnRight().position.x(112);
	view.add(createColumn(movingColumn, movingColumnButton));
	movingColumn().shadowColor("#000");
	movingColumn().zIndex(1);

	yield* waitFor(0.6);

	yield* movingColumnButton().fill("#ffffff39", 0.2);
	yield* waitFor(0.4);
	yield* all(movingColumn().scale(1.13, 0.3), movingColumn().shadowBlur(20, 0.3));
	yield* waitFor(0.3);

	const timingFunc = easeInOutSine;
	yield* movingColumn().position.x(-152, 0.6, timingFunc);
	yield* columnLeft().position.x(0, 0.5);
	yield* movingColumn().position.x(152, 0.8, timingFunc);
	yield* all(columnLeft().position.x(-112, 0.5), columnRight().position.x(0, 0.5));
	yield* movingColumn().position.x(0, 0.6, timingFunc);
	yield* columnRight().position.x(112, 0.5);

	yield* waitFor(0.15);
	yield* all(
		movingColumnButton().fill("#ffffff00", 0.2),
		movingColumn().scale(1, 0.3),
		movingColumn().shadowBlur(0, 0.3),
	);

	yield* waitFor(0.6);
});

function createColumn(columnRef?: Reference<Layout>, columnButtonRef?: Reference<Rect>) {
	return (
		<Layout layout ref={columnRef} gap={12} direction={"column"} alignItems={"center"}>
			<Rect
				ref={columnButtonRef}
				size={[100, 50]}
				fill={"#ffffff00"}
				radius={20}
				layout
				alignItems={"center"}
				justifyContent={"center"}
			>
				{/* <Txt fill={"#fff"} text={"1"} textAlign={"center"} /> */}
				<Rect size={[20, 30]} fill={"#c6c6c6"} radius={5} />
			</Rect>

			{createTile()}
			{createTile()}
			{createTile()}
			{createTile()}
		</Layout>
	);
}

function createTile(ref?: Reference<Rect>) {
	return <Rect ref={ref} size={[100, 100]} fill={"#4ecca3"} radius={20} />;
}
