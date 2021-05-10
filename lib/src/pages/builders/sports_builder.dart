import "package:flutter/material.dart";

import "package:ramaz/data.dart";
import "package:ramaz/models.dart";
import "package:ramaz/widgets.dart";

/// A row in a form. 
/// 
/// Displays a title or header on the left, and a picker on the right.
class FormRow extends StatelessWidget {
	/// The title to show. 
	final String title;

	/// The picker for user input. 
	final Widget picker;

	/// Whether to constrict [picker]'s size. 
	final bool sized;

	/// Whether this widget needs more space on the bottom. 
	/// 
	/// Widgets that use [sized] don't need this, since their [picker] is big
	/// enough to provide padding on the bottom as well. Hence, this is only 
	/// set to true for widgets created with [FormRow.editable()], since those
	/// never use a big [picker].
	final bool moreSpace;

	/// Creates a row in a form.
	const FormRow(this.title, this.picker, {this.sized = false}) : 
		moreSpace = false;

	/// A [FormRow] where the right side is represented by an [Icon]  
	/// 
	/// When [value] is null, [whenNull] is displayed. Otherwise, [value] is 
	/// displayed in a [Text] widget. Both widgets, when tapped, call 
	/// [setNewValue].
	FormRow.editable({
		required this.title,
		required VoidCallback setNewValue,
		required IconData whenNull,
		String? value,
	}) : 
		sized = false,
		moreSpace = true,
		picker = value == null
			? IconButton(
				icon: Icon(whenNull),
				onPressed: setNewValue
			)
			: InkWell(
				onTap: setNewValue,
				child: Text(
					value,
					style: const TextStyle(color: Colors.blue),
				),
			);

	@override
	Widget build(BuildContext context) => Column(
		children: [
			Row(
				mainAxisAlignment: MainAxisAlignment.spaceEvenly,
				children: [
					Text(title), 
					const Spacer(), 
					if (sized) Container(
						constraints: const BoxConstraints(
							maxWidth: 200, 
							maxHeight: 75,
						),
						child: picker,
					)
					else picker
				]
			),
			SizedBox(height: moreSpace ? 25 : 15),
		]
	);
}

/// A page to create a Sports game. 
/// 
/// This widget is stateful to provide a [TextEditingController] that has its 
/// text preset to [parent]'s properties (if applicable). All state is still 
/// managed by the view model. 
class SportsBuilder extends StatefulWidget {
	/// Opens a form for the user to 
	static Future<SportsGame?> createGame(
		BuildContext context, 
		[SportsGame? parent]
	) => Navigator.of(context).push<SportsGame>(
		MaterialPageRoute(
			builder: (BuildContext context) => SportsBuilder(parent),
		)
	);

	/// Fills all the properties on this page with the properties of this game.
	final SportsGame? parent;

	/// Creates a page to build a [SportsGame].
	/// 
	/// Passing in [parent] will fill in the properties of the page with the 
	/// properties of [parent].
	const SportsBuilder([this.parent]);

	@override
	SportBuilderState createState() => SportBuilderState();
}

/// A state for [SportsBuilder].
/// 
/// This state keeps [TextEditingController]s intact. 
class SportBuilderState extends ModelListener<
	SportsBuilderModel, SportsBuilder
> {
	/// A controller to hold [SportsBuilder.parent]'s team name.
	final TextEditingController teamController = TextEditingController();

	/// A controller to hold [SportsBuilder.parent]'s opponent.
	final TextEditingController opponentController = TextEditingController();

	@override
	SportsBuilderModel getModel() => SportsBuilderModel(widget.parent);

	@override
	void initState() {
		teamController.text = widget.parent?.team ?? "";
		opponentController.text = widget.parent?.opponent ?? "";
		super.initState();
	}

	@override
	void dispose() {
		teamController.dispose();
		opponentController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) => Scaffold(
		appBar: AppBar(title: const Text("Add game")),
		bottomSheet: !model.loading ? null : Container(
			height: 60, 
			padding: const EdgeInsets.all(10),
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceBetween,
				children: const [Text("Saving..."), CircularProgressIndicator()]
			)
		),
		body: ListView(
			padding: const EdgeInsets.all(20),
			children: [
				FormRow(
					"Sport",
					DropdownButtonFormField<Sport>(
						hint: const Text("Choose a sport"),
						value: model.sport,
						onChanged: (Sport? value) => model.sport = value,
						items: [
							for (final Sport sport in Sport.values) 
								DropdownMenuItem<Sport>(
									value: sport,
									child: Text(SportsGame.capitalize(sport))
								)
						],
					),
					sized: true,
				),
				FormRow(
					"Team",
					TextField(
						onChanged: (String value) => model.team = value,
						textCapitalization: TextCapitalization.words,
						controller: teamController,
					),
					sized: true,
				),
				FormRow(
					"Opponent",
					TextField(
						onChanged: (String value) => model.opponent = value,
						textCapitalization: TextCapitalization.words,
						controller: opponentController,
					),
					sized: true,
				),
				FormRow(
					"Away game",
					Checkbox(
						value: model.away,
						// If tristate == false (default), value never be null
						onChanged: (bool? value) => model.away = value!,
					),
				),
				FormRow.editable(
					title: "Date",
					value: SportsTile.formatDate(model.date),
					whenNull: Icons.date_range,
					setNewValue: () async => model.date = await pickDate(
						initialDate: DateTime.now(),
						context: context
					),
				),
				FormRow.editable(
					title: "Start time",
					value: model.start?.format(context),
					whenNull: Icons.access_time,
					setNewValue: () async => model.start = await showTimePicker(
						context: context,
						initialTime: model.start ?? TimeOfDay.now(),
					),
				),
				FormRow.editable(
					title: "End time",
					value: model.end?.format(context),
					whenNull: Icons.access_time,
					setNewValue: () async => model.end = await showTimePicker(
						context: context,
						initialTime: model.end ?? TimeOfDay.now(),
					),
				),
				const SizedBox(height: 10),
				Row(
					mainAxisAlignment: MainAxisAlignment.spaceBetween,
					children: [
						const Text(
							"Tap on the card to change the scores", 
							textScaleFactor: 0.9
						),
						TextButton(
							onPressed: () => model.scores = null,
							child: const Text("Clear"),
						)
					]
				),
				const SizedBox(height: 20),
				if (model.ready) SportsTile(
					model.game,
					onTap: () async => model.scores = 
						await SportsScoreUpdater.updateScores(context, model.game) 
							?? model.scores
			),
				ButtonBar(
					children: [
						TextButton(
							onPressed: () => Navigator.of(context).pop(),
							child: const Text("Cancel"),
						),
						ElevatedButton(
							onPressed: !model.ready ? null : 
								() => Navigator.of(context).pop(model.game),
							child: const Text("Save"),
						)
					]
				)
			]
		)
	);
}
