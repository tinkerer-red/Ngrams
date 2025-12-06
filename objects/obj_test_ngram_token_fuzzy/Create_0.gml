var tok_if           = "tok_if";
var tok_identifier   = "tok_identifier";
var tok_assign       = "tok_assign";
var tok_number       = "tok_number";
var tok_semicolon    = "tok_semicolon";
var tok_paren_open   = "tok_paren_open";
var tok_paren_close  = "tok_paren_close";
var tok_block_open   = "tok_block_open";
var tok_block_close  = "tok_block_close";

// Sample lexicon of token sequences
var _pattern_if_assign = [ tok_if, tok_identifier, tok_assign, tok_number, tok_semicolon ];
var _pattern_if_paren  = [ tok_if, tok_paren_open, tok_identifier, tok_paren_close, tok_block_open, tok_block_close ];
var _pattern_plain     = [ tok_identifier, tok_assign, tok_number, tok_semicolon ];

var _fuzzy = new NgramTokenFuzzy(1, 3, 10);
_fuzzy.train([
    _pattern_if_assign,
    _pattern_if_paren,
    _pattern_plain
]);

// Input that is "close" to if-assign
var _input_seq = [ tok_if, tok_identifier, tok_assign ];

_fuzzy.search(_input_seq);

var _values  = _fuzzy.get_value_array();   // arrays of tokens from lexicon
var _scores  = _fuzzy.get_score_array();   // strength values
var _results = _fuzzy.get_result_array();  // full entries

var _best = _fuzzy.search_best(_input_seq);

show_debug_message("")
show_debug_message("NgramTokenFuzzy::")
show_debug_message("values  = " + string(_values));
show_debug_message("scores  = " + string(_scores));
show_debug_message("results = " + string(_results));
show_debug_message("best    = " + string(_best));
show_debug_message("")