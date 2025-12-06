#region jsDoc
/// @func  NgramStringPredict()
/// @desc  Predictive n-gram model for strings. Trains on sequences of
///        characters and predicts the most likely next character given a
///        string prefix. Uses variable-order n-grams between n_gram_min
///        and n_gram_max.
/// @param {Real} _n_gram_min  : Minimum n-gram order (context length).
/// @param {Real} _n_gram_max  : Maximum n-gram order (context length).
/// @param {Real} _max_results : Maximum number of prediction results.
/// @param {Bool} _case_sense  : Whether training and prediction are case-sensitive.
/// @returns {Struct.NgramStringPredict}
#endregion
function NgramStringPredict(_n_gram_min=1, _n_gram_max=25, _max_results=10, _case_sense=true)
	: NgramBase(_n_gram_min, _n_gram_max, _max_results) constructor {
	
	#region jsDoc
	/// @func  train()
	/// @desc  Train the predictive model from an array of strings.
	///        For each string, character n-grams (orders from n_gram_min
	///        to n_gram_max) are used as contexts, and the next character
	///        occurrences are counted.
	/// @param {Array<String>} _string_array
	/// @returns {Struct.NgramStringPredict}
	#endregion
	static train = function(_string_array) {
		static __add_observation = function(_context_string, _next_char) {
	        var _entry_struct = __context_dict[$ _context_string];
	        if (_entry_struct == undefined) {
	            _entry_struct = {
	                counts: {},
	                total : 0
	            };
	            __context_dict[$ _context_string] = _entry_struct;
	        }

	        var _counts_struct = _entry_struct.counts;
	        var _old_count     = _counts_struct[$ _next_char];

	        if (_old_count == undefined) {
	            _counts_struct[$ _next_char] = 1;
	        }
	        else {
	            _counts_struct[$ _next_char] = _old_count + 1;
	        }

	        _entry_struct.total += 1;
	    };
		
		__clear_model();
		
		var _array_length = array_length(_string_array);
		var _index_array  = 0;

		while (_index_array < _array_length) {
			var _raw_string = _string_array[_index_array];

			var _source_string = __case_sense ? _raw_string : string_lower(_raw_string);
			var _string_length = string_length(_source_string);

			// Need at least 2 characters to have context + next
			if (_string_length > 1) {
				var _position_index = 2; // index of "next character" in 1-based string indexing

				while (_position_index <= _string_length) {
					var _max_context = min(nGramMax, _position_index - 1);
					var _context_size = nGramMin;

					while (_context_size <= _max_context) {
						var _context_start = (_position_index - _context_size);
						var _context_string = string_copy(_source_string, _context_start, _context_size);

						var _next_char = string_char_at(_source_string, _position_index);

						__add_observation(_context_string, _next_char);

						_context_size++;
					}

					_position_index++;
				}
			}

			_index_array++;
		}

		return self;
	};

	// EXPORT / LOAD

	#region jsDoc
	/// @func  export()
	/// @desc  Export the predictive model as a struct suitable for json_encode().
	/// @returns {Struct}
	#endregion
	static export = function() {
		var _model_struct = {
			type        : "NgramStringPredict",
			n_gram_min  : nGramMin,
			n_gram_max  : nGramMax,
			max_results : maxResults,
			case_sense  : __case_sense,
			context_dict: __context_dict
		};
		return _model_struct;
	};

	#region jsDoc
	/// @func  load()
	/// @desc  Load a predictive model from an exported struct.
	/// @param {Struct} _model_struct
	/// @returns {Struct.NgramStringPredict}
	#endregion
	static load = function(_model_struct) {
		// Shared config from base
		static __parent_load = NgramBase.load;
		__parent_load(_model_struct);

		__case_sense  = (_model_struct[$ "case_sense"])  ? _model_struct.case_sense  : __case_sense;
		__context_dict = (_model_struct[$ "context_dict"]) ? _model_struct.context_dict : {};

		__input = "";
		__clear_results();
		return self;
	};

	// PREDICTION

	#region jsDoc
	/// @func  predict()
	/// @desc  Predict the next character(s) for the given prefix string.
	///        Populates the internal result arrays with structs:
	///        {
	///            value       : String (single character),
	///            probability : Real (0..1),
	///        }
	/// @param {String} _prefix_string
	/// @returns {Struct.NgramStringPredict}
	#endregion
	static predict = function(_prefix_string) {
		__clear_results();
		__input = _prefix_string;

		var _source_string = __case_sense ? _prefix_string : string_lower(_prefix_string);
		var _prefix_length = string_length(_source_string);

		if (_prefix_length <= 0) {
			__mark_results_dirty();
			return self;
		}

		// Aggregate scores from all matching context orders
		var _score_struct = {};
		var _weight_sum   = 0;

		var _order_value = nGramMin;
		while (_order_value <= nGramMax) {
			if (_prefix_length >= _order_value) {
				var _context_start = (_prefix_length - _order_value) + 1;
				var _context_string = string_copy(_source_string, _context_start, _order_value);

				var _entry_struct = __context_dict[$ _context_string];

				if (_entry_struct != undefined && _entry_struct.total > 0) {
					var _counts_struct = _entry_struct.counts;
					var _total_count   = _entry_struct.total;

					var _weight_value = _order_value; // longer context -> higher weight
					_weight_sum += _weight_value;

					var _char_names = variable_struct_get_names(_counts_struct);
					var _char_count = array_length(_char_names);
					var _char_index = 0;

					while (_char_index < _char_count) {
						var _char_value = _char_names[_char_index];
						var _count_value = _counts_struct[$ _char_value];

						var _prob_value = _count_value / _total_count;

						var _old_score = _score_struct[$ _char_value];
						if (_old_score == undefined) {
							_score_struct[$ _char_value] = _prob_value * _weight_value;
						}
						else {
							_score_struct[$ _char_value] = _old_score + (_prob_value * _weight_value);
						}

						_char_index++;
					}
				}
			}

			_order_value++;
		}

		// Convert scores into result entries
		if (_weight_sum > 0) {
			var _names_array  = variable_struct_get_names(_score_struct);
			var _names_length = array_length(_names_array);
			var _names_index  = 0;

			while (_names_index < _names_length) {
				var _char_value   = _names_array[_names_index];
				var _score_value  = _score_struct[$ _char_value];
				var _probability  = _score_value / _weight_sum;
				
				var _entry = {
					value      : _char_value,
					probability: _probability
				};

				array_push(__result_array, _entry);

				_names_index++;
			}
		}

		__finalize_results();
		return self;
	};

	#region jsDoc
	/// @func  predict_best()
	/// @desc  Convenience helper. Predicts next characters for the given prefix
	///        and returns only the most likely next character, or undefined
	///        if there are no results.
	/// @param {String} _prefix_string
	/// @returns {String|Undefined}
	#endregion
	static predict_best = function(_prefix_string=__input) {
		predict(_prefix_string);
		return get_top_value();
	};
	
	#region Private
	
	__case_sense = _case_sense;

	// context -> { counts: struct(char -> count), total: real }
	__context_dict = {};

	// Optional: last prefix used, mostly for debug / tooling
	__input = "";

	// Hook value and score extractors for the base
	static __get_value = function(_entry_struct) {
		return _entry_struct.value; // predicted character
	};

	static __get_score = function(_entry_struct) {
		return _entry_struct.probability; // 0..1
	};

	static __compare = function(_entry_a, _entry_b) {
		var _difference = _entry_b.probability - _entry_a.probability;
		if (_difference > 0) return 1;
		if (_difference < 0) return -1;
		return 0;
	};

	static __clear_model = function() {
		__context_dict = {};
		__input  = "";
		__clear_results();
	};
	
	#endregion
}
