import { Circle, Layout, Rect, Txt, makeScene2D } from "@motion-canvas/2d";
import { all, any, createRef, Reference, waitFor } from "@motion-canvas/core";

export default makeScene2D(function* (view) {
	const columnButton = createRef<Rect>();
	const column = createRef<Layout>();
	view.add(createColumn(column, columnButton));

	yield* waitFor(0.6);

	const columnDialog = createRef<Rect>();
	view.add(
		<Rect
			ref={columnDialog}
			size={[250, 300]}
			fill={"#393e46"}
			radius={20}
			top={columnButton().bottom()}
			opacity={0}
			scale={[1, 0.3]}
			offsetY={-1}
		/>,
	);

	yield* any(
		columnButton().fill("#ffffff49", 0.2),
		columnDialog().opacity(1, 0.1),
		columnDialog().position.y(columnDialog().position().y + 10, 0.3),
		columnDialog().scale.y(1, 0.2),
	);
	yield* all(columnButton().fill("#ffffff00", 0.2));

	yield* waitFor(1.5);

	yield* columnDialog().opacity(0, 0.2);
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
