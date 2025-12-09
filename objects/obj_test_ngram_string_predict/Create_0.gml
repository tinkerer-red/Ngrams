ngram = new NgramStringPredict(1, 4, 10, false);

ngram.train(WordArray());

//Start with a basic search term
keyboard_string = "GameMaker";

input = keyboard_string
next_best = undefined;