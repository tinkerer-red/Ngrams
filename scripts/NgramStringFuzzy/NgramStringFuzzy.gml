#region jsDoc
/// @func  NgramStringFuzzy()
/// @desc  Fuzzy n-gram string matcher. Builds substring n-grams from
///        a lexicon of strings and ranks matches to an input string.
/// @param {Real} _n_gram_min  : Minimum n-gram length.
/// @param {Real} _n_gram_max  : Maximum n-gram length.
/// @param {Real} _max_results : Maximum number of results to return.
/// @param {Bool} _case_sense  : Whether matching is case-sensitive.
/// @returns {Struct.NgramStringFuzzy}
#endregion
function NgramStringFuzzy(_n_gram_min=1, _n_gram_max=10, _max_results=10, _case_sense=true)
	: NgramBase(_n_gram_min, _n_gram_max, _max_results) constructor {
	
	#region jsDoc
	/// @func  train()
	/// @desc  Train the fuzzy model from a lexicon array (build substring grams).
	/// @param {Array<String>} _lexicon_array
	/// @returns {Struct.NgramStringFuzzy}
	#endregion
	static train = function(_lexicon_array) {
		__clear_lexicon();
		
		static __push_substring_function = function(_substring_value, _source_string)
		{
			var _array_ref = __ngram_dict[$ _substring_value];
			if (!is_array(_array_ref))
			{
				_array_ref = [_source_string];
				__ngram_dict[$ _substring_value] = _array_ref;
			}
			else
			{
				if (!array_contains(_array_ref, _source_string))
				{
					array_push(_array_ref, _source_string);
				}
			}
		};
		
		var _completed_grams_array = [];
		var _lexicon_length        = array_length(_lexicon_array);
		
		var _lexicon_index = 0;
		while (_lexicon_index < _lexicon_length)
		{
			var _source_string = __case_sense
				? _lexicon_array[_lexicon_index]
				: string_lower(_lexicon_array[_lexicon_index]);

			__exact_dict[$ _source_string] = true;

			var _string_value  = _source_string;
			var _source_length = string_length(_source_string);

			var _local_min   = nGramMin;
			var _local_max   = min(nGramMax, _source_length);
			var _length_span = _local_max - _local_min;

			array_resize(_completed_grams_array, 0);

			var _current_size = _local_min;
			var _size_index   = 0;
			while (_size_index <= _length_span)
			{
				var _position_index = 1;
				var _max_position   = _source_length - _current_size + 1;

				while (_position_index <= _max_position)
				{
					var _gram_substring = string_copy(_string_value, _position_index, _current_size);

					if (!array_contains(_completed_grams_array, _gram_substring))
					{
						__push_substring_function(_gram_substring, _source_string);
						array_push(_completed_grams_array, _gram_substring);
					}

					_position_index++;
				}

				_current_size++;
				_size_index++;
			}

			_lexicon_index++;
		}
		
		return self;
	};
	
	// EXPORT / LOAD
	
	#region jsDoc
	/// @func  export()
	/// @desc  Export the fuzzy model as a struct suitable for json_encode().
	/// @returns {Struct}
	#endregion
	static export = function() {
		var _model_struct = {
			type        : "NgramStringFuzzy",
			n_gram_min  : nGramMin,
			n_gram_max  : nGramMax,
			max_results : maxResults,
			case_sense  : __case_sense,
			exact_dict  : __exact_dict,
			ngram_dict  : __ngram_dict
		};
		return _model_struct;
	};
	
	#region jsDoc
	/// @func  load()
	/// @desc  Load a fuzzy model from an exported struct.
	/// @param {Struct} _model_struct
	/// @returns {Struct.NgramStringFuzzy}
	#endregion
	static load = function(_model_struct) {
		// Shared config from base
		static __parent_load = NgramBase.load;
		__parent_load(_model_struct);
		
		__case_sense = (_model_struct[$ "case_sense"]) ? _model_struct.case_sense : __case_sense;
		__exact_dict = (_model_struct[$ "exact_dict"]) ? _model_struct.exact_dict : {};
		__ngram_dict = (_model_struct[$ "ngram_dict"]) ? _model_struct.ngram_dict : {};
		
		__input = "";
		__clear_results();
		return self;
	};
	
	// LEXICON / SEARCH
	
	#region jsDoc
	/// @func  search()
	/// @desc  Perform a fuzzy search against the trained lexicon, updating
	///        the internal result arrays. Returns self for chaining.
	///        This variant:
	///        - Searches from the largest n-grams downwards
	///        - Only creates new candidates while candidate_count < maxResults
	///        - Continues to accumulate strength for existing entries
	///        - Culls candidates whose length is outside [75%, 125%] of the
	///          input length (clamped so lower bound is never below 2).
	/// @param {String} _input_string
	/// @returns {Struct.NgramStringFuzzy}
	#endregion
	static search = function(_input_string) {
	    if (__input = _input_string) {
			return;
		}
	
		var _use_case_sense = __case_sense;
	    var _use_n_gram_min = nGramMin;
	    var _use_n_gram_max = nGramMax;
	
	    __clear_results();
	    __input = _input_string;

	    var _result_dict_struct = {};
	    var _result_array_ref   = __result_array;

	    // Exact match gets "infinity" strength
	    if (variable_struct_exists(__exact_dict, _input_string)) {
	        var _exact_entry = {
	            word    : _input_string,
	            strength: infinity
	        };

	        array_push(_result_array_ref, _exact_entry);
	        _result_dict_struct[$ _input_string] = _exact_entry;
	    }

	    var _source_string = _use_case_sense ? _input_string : string_lower(_input_string);
	    var _source_length = string_length(_source_string);

	    if (_source_length <= 0) {
	        __mark_results_dirty();
	        return self;
	    }

	    // Length gating: only consider candidates whose length is within
	    // [75%, 125%] of the input length, with a lower bound of 2.
	    var _min_match_length = max(2, floor(_source_length * 0.75));
	    var _max_match_length = max(2, ceil(_source_length * 1.25));
	
	    var _string_value = _source_string;

	    _use_n_gram_max = min(_use_n_gram_max, _source_length);
	    if (_use_n_gram_min > _use_n_gram_max) {
	        _use_n_gram_min = _use_n_gram_max;
	    }

	    var _current_size = _use_n_gram_max;

	    while (_current_size >= _use_n_gram_min) {
	        var _position_index = 1;
	        var _max_position   = _source_length - _current_size + 1;

	        while (_position_index <= _max_position) {
	            var _gram_substring = string_copy(_string_value, _position_index, _current_size);

	            var _match_array = __ngram_dict[$ _gram_substring];

	            if (is_array(_match_array)) {
	                var _match_length = array_length(_match_array);
	                var _match_index  = 0;

	                while (_match_index < _match_length) {
	                    var _found_string = _match_array[_match_index];
					
	                    // Length gate: drop obviously too short/long candidates
	                    var _found_length = string_length(_found_string);
	                    if (_found_length < _min_match_length || _found_length > _max_match_length) {
	                        _match_index++;
	                        continue;
	                    }

	                    var _existing_entry = _result_dict_struct[$ _found_string];
	                    if (_existing_entry == undefined) {
	                        // Only create a new candidate if we are still under maxResults
	                        if (array_length(_result_array_ref) < maxResults) {
	                            var _new_entry = {
	                                word    : _found_string,
	                                strength: 1
	                            };

	                            _result_dict_struct[$ _found_string] = _new_entry;
	                            array_push(_result_array_ref, _new_entry);
	                        }
	                        // else: ignore new candidate, we are past cap
	                    }
	                    else {
	                        _existing_entry.strength += 1;
	                    }

	                    _match_index++;
	                }
	            }

	            _position_index++;
	        }

	        _current_size--;
	    }

	    __mark_results_dirty();
	    return self;
	};
	
	#region jsDoc
	/// @func  search_best()
	/// @desc  Convenience helper. Performs a fuzzy search and returns only the
	///        best-matching word (string), or undefined if there are no results.
	/// @param {String} _input_string
	/// @returns {String|Undefined}
	#endregion
	static search_best = function(_input_string=__input) {
	    search(_input_string);
	    return get_top_value();
	};
	
	#region Private
	
	__case_sense = _case_sense;
	
	__exact_dict    = {};
	__ngram_dict    = {};
	__input = ""; // only used to prevent re-searching when value is unchanged
	
	// Hook value and score extractors for the base
	static __get_value = function(_entry_struct) {
		return _entry_struct.word;
	};
	
	static __get_score = function(_entry_struct) {
		return _entry_struct.strength;
	};
	
	static __compare = function(_entry_a, _entry_b) {
		var _difference = _entry_b.strength - _entry_a.strength;
		if (_difference > 0) return 1;
		if (_difference < 0) return -1;
		return 0;
	};
	
	static __clear_lexicon = function()
	{
		__exact_dict    = {};
		__ngram_dict    = {};
		__input = "";
		__clear_results();
	};
	
	#endregion
}


