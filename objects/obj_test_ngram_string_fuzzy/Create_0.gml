//Create a string matching handler
ngram = new NgramStringFuzzy(1, 4, 10, false);

//Give the handler a "lexicon" (dictionary) to work from
ngram.train(WordArray());

//Start with a basic search term
keyboard_string = "GameMaker";