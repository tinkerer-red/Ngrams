//Update the string to whatever the user has typed in
//If the string changes, we restart the search
ngram.predict(keyboard_string);
if (keyboard_string != input) {
	input = keyboard_string;
	next_best = ngram.predict_next_best(10);
}