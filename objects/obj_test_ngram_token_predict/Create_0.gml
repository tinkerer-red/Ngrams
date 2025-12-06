var tok_if           = "tok_if";
var tok_while        = "tok_while";
var tok_for          = "tok_for";

var tok_identifier   = "tok_identifier";
var tok_identifier_2 = "tok_identifier_2";

var tok_assign       = "tok_assign";
var tok_plus         = "tok_plus";

var tok_number       = "tok_number";
var tok_string       = "tok_string";

var tok_true         = "tok_true";
var tok_false        = "tok_false";

var tok_semicolon    = "tok_semicolon";
var tok_paren_open   = "tok_paren_open";
var tok_paren_close  = "tok_paren_close";
var tok_block_open   = "tok_block_open";
var tok_block_close  = "tok_block_close";


// Example tokens: could be enums, ints, strings, whatever
// if x = 10;
var _seq_if_assign_number_1 = [
    tok_if, tok_identifier, tok_assign, tok_number, tok_semicolon
];

// if x = 20;
var _seq_if_assign_number_2 = [
    tok_if, tok_identifier, tok_assign, tok_number, tok_semicolon
];

// if x = "hello";
var _seq_if_assign_string = [
    tok_if, tok_identifier, tok_assign, tok_string, tok_semicolon
];

// if x = y;
var _seq_if_assign_identifier = [
    tok_if, tok_identifier, tok_assign, tok_identifier_2, tok_semicolon
];

// x = 42;
var _seq_plain_assign_number_1 = [
    tok_identifier, tok_assign, tok_number, tok_semicolon
];

// x = 100;
var _seq_plain_assign_number_2 = [
    tok_identifier, tok_assign, tok_number, tok_semicolon
];

// x = "world";
var _seq_plain_assign_string = [
    tok_identifier, tok_assign, tok_string, tok_semicolon
];

// if (x) { }
var _seq_if_paren_block = [
    tok_if, tok_paren_open, tok_identifier, tok_paren_close, tok_block_open, tok_block_close
];

// while (x) { }
var _seq_while_paren_block = [
    tok_while, tok_paren_open, tok_identifier, tok_paren_close, tok_block_open, tok_block_close
];

// for (i = 0; i; i) { }
var _seq_for_header = [
    tok_for, tok_paren_open,
    tok_identifier, tok_assign, tok_number, tok_semicolon,
    tok_identifier, tok_semicolon,
    tok_identifier, tok_paren_close,
    tok_block_open, tok_block_close
];


// Training + predictions
var _model = new NgramTokenPredict(1, 4, 10);

var _corpus_array = [
    _seq_if_assign_number_1,
    _seq_if_assign_number_2,
    _seq_if_assign_string,
    _seq_if_assign_identifier,
    _seq_plain_assign_number_1,
    _seq_plain_assign_number_2,
    _seq_plain_assign_string,
    _seq_if_paren_block,
    _seq_while_paren_block,
    _seq_for_header
];

_model.train(_corpus_array);


var _prefix_if_assign = [ tok_if, tok_identifier, tok_assign ];

_model.predict(_prefix_if_assign);

var _candidates_if = _model.get_value_array();     // tokens
var _scores_if     = _model.get_score_array();     // probabilities 0..1
var _results_if    = _model.get_result_array();    // full structs
var _best_if       = _model.predict_best(_prefix_if_assign);

show_debug_message("NgramTokenPredict::")
show_debug_message("prefix: [tok_if, tok_identifier, tok_assign]");
show_debug_message("_candidates_if = " + string(_candidates_if));
show_debug_message("_scores_if     = " + string(_scores_if));
show_debug_message("_results_if    = " + string(_results_if));
show_debug_message("_best_if       = " + string(_best_if));
show_debug_message("")