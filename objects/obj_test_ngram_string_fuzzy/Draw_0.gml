//Display results
var _string = "";
_string += "Ngram String Fuzzy Search\n";
_string += "Tinkerer_Red 2025-12-05\n";
_string += "\n";
_string += "Type to search for a word\n";
_string += "Input = \"" + keyboard_string + "\"\n";
_string += "\n";
_string += "Best Word = \"" + string(ngram.search_best()) + "\"\n";
_string += "\n";
_string += "Words = \"" + string(ngram.get_value_array()) + "\"\n";
_string += "Strengths = \"" + string(ngram.get_score_array()) + "\"\n";
_string += "\n";
_string += "Results = \"" + string(ngram.get_result_array()) + "\"\n";
draw_text(x, y, _string);