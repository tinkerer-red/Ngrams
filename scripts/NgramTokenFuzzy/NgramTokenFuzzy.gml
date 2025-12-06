#region jsDoc
/// @func  NgramTokenFuzzy()
/// @desc  Fuzzy n-gram matcher for token sequences. Builds token n-grams from
///        a lexicon of token arrays and ranks lexicon sequences against an
///        input token sequence based on overlapping n-grams.
/// @param {Real} _n_gram_min  : Minimum n-gram length (in tokens).
/// @param {Real} _n_gram_max  : Maximum n-gram length (in tokens).
/// @param {Real} _max_results : Maximum number of results to return.
/// @returns {Struct.NgramTokenFuzzy}
#endregion
function NgramTokenFuzzy(_n_gram_min=1, _n_gram_max=10, _max_results=10)
	: NgramBase(_n_gram_min, _n_gram_max, _max_results) constructor {
	
	#region jsDoc
	/// @func  train()
	/// @desc  Train the fuzzy model from a lexicon array of token sequences.
	///        Each element of _tokens_array should be an Array of tokens.
	///        Builds token n-grams for orders between n_gram_min and n_gram_max.
	/// @param {Array<Array>} _tokens_array
	/// @returns {Struct.NgramTokenFuzzy}
	#endregion
	static train = function(_tokens_array) {
		__clear_lexicon();

		var _completed_grams_array = [];

		var _outer_length = array_length(_tokens_array);
		var _outer_index  = 0;

		while (_outer_index < _outer_length) {
			var _sequence = _tokens_array[_outer_index];

			if (is_array(_sequence)) {
				var _seq_length = array_length(_sequence);

				if (_seq_length > 0) {
					// Store sequence in lexicon and get its index
					var _lex_index = array_length(__lexicon_sequences);
					array_push(__lexicon_sequences, _sequence);

					// Exact match key for the whole sequence
					var _full_key = __encode_sequence_key(_sequence, 0, _seq_length);
					__exact_dict[$ _full_key] = _lex_index;

					// Build n-grams
					var _local_min   = nGramMin;
					var _local_max   = min(nGramMax, _seq_length);
					var _length_span = _local_max - _local_min;

					array_resize(_completed_grams_array, 0);

					var _current_size = _local_min;
					var _size_index   = 0;
					while (_size_index <= _length_span) {
						var _start_index = 0;
						var _max_start   = _seq_length - _current_size;

						while (_start_index <= _max_start) {
							var _key = __encode_sequence_key(_sequence, _start_index, _current_size);

							if (!array_contains(_completed_grams_array, _key)) {
								var _index_array = __ngram_dict[$ _key];
								if (!is_array(_index_array)) {
									_index_array = [ _lex_index ];
									__ngram_dict[$ _key] = _index_array;
								}
								else {
									if (!array_contains(_index_array, _lex_index)) {
										array_push(_index_array, _lex_index);
									}
								}

								array_push(_completed_grams_array, _key);
							}

							_start_index++;
						}

						_current_size++;
						_size_index++;
					}
				}
			}

			_outer_index++;
		}

		return self;
	};

	// EXPORT / LOAD

	#region jsDoc
	/// @func  export()
	/// @desc  Export the token fuzzy model as a struct suitable for json_encode().
	/// @returns {Struct}
	#endregion
	static export = function() {
		var _model_struct = {
			type             : "NgramTokenFuzzy",
			n_gram_min       : nGramMin,
			n_gram_max       : nGramMax,
			max_results      : maxResults,
			lexicon_sequences: __lexicon_sequences,
			exact_dict       : __exact_dict,
			ngram_dict       : __ngram_dict
		};
		return _model_struct;
	};

	#region jsDoc
	/// @func  load()
	/// @desc  Load a token fuzzy model from an exported struct.
	/// @param {Struct} _model_struct
	/// @returns {Struct.NgramTokenFuzzy}
	#endregion
	static load = function(_model_struct) {
		static __parent_load = NgramBase.load;
		__parent_load(_model_struct);

		__lexicon_sequences = (_model_struct[$ "lexicon_sequences"]) ? _model_struct.lexicon_sequences : [];
		__exact_dict        = (_model_struct[$ "exact_dict"])        ? _model_struct.exact_dict        : {};
		__ngram_dict        = (_model_struct[$ "ngram_dict"])        ? _model_struct.ngram_dict        : {};

		__input = [];
		__clear_results();
		return self;
	};

	// SEARCH

	#region jsDoc
	/// @func  search()
	/// @desc  Perform a fuzzy search against the trained lexicon using token
	///        n-grams, updating the internal result arrays. Returns self for
	///        chaining. The input should be an array of tokens.
/// @param {Array} _input_tokens
/// @returns {Struct.NgramTokenFuzzy}
	#endregion
	static search = function(_input_tokens) {
		__clear_results();
		__input = _input_tokens;

		if (!is_array(_input_tokens)) {
			__mark_results_dirty();
			return self;
		}

		var _result_dict = {};
		var _result_array_ref = __result_array;

		var _input_length = array_length(_input_tokens);

		// Exact match check
		if (_input_length > 0) {
			var _full_key = __encode_sequence_key(_input_tokens, 0, _input_length);
			var _exact_index = __exact_dict[$ _full_key];

			if (_exact_index != undefined) {
				var _seq_exact = __lexicon_sequences[_exact_index];

				var _exact_entry = {
					value    : _seq_exact,
					strength : infinity,
					lex_index: _exact_index
				};

				array_push(_result_array_ref, _exact_entry);
				_result_dict[$ string(_exact_index)] = _exact_entry;
			}
		}

		if (_input_length <= 0) {
			__mark_results_dirty();
			return self;
		}

		var _local_min   = nGramMin;
		var _local_max   = min(nGramMax, _input_length);
		var _length_span = _local_max - _local_min;

		var _current_size = _local_min;
		var _size_index   = 0;

		while (_size_index <= _length_span) {
			var _start_index = 0;
			var _max_start   = _input_length - _current_size;

			while (_start_index <= _max_start) {
				var _key = __encode_sequence_key(_input_tokens, _start_index, _current_size);

				var _indices_array = __ngram_dict[$ _key];

				if (is_array(_indices_array)) {
					var _indices_length = array_length(_indices_array);
					var _indices_index  = 0;

					while (_indices_index < _indices_length) {
						var _lex_index = _indices_array[_indices_index];

						var _result_key = string(_lex_index);
						var _existing_entry = _result_dict[$ _result_key];

						if (_existing_entry == undefined) {
							var _seq_value = __lexicon_sequences[_lex_index];

							var _new_entry = {
								value    : _seq_value,
								strength : 1,
								lex_index: _lex_index
							};

							_result_dict[$ _result_key] = _new_entry;
							array_push(_result_array_ref, _new_entry);
						}
						else {
							_existing_entry.strength += 1;
						}

						_indices_index++;
					}
				}

				_start_index++;
			}

			_current_size++;
			_size_index++;
		}

		__mark_results_dirty();
		return self;
	};

	#region jsDoc
	/// @func  search_best()
	/// @desc  Convenience helper. Performs a token fuzzy search and returns
	///        only the best-matching sequence (array of tokens), or undefined
	///        if there are no results.
	/// @param {Array} _input_tokens
	/// @returns {Array|Undefined}
	#endregion
	static search_best = function(_input_tokens=_input) {
		search(_input_tokens);
		return get_top_value();
	};
	
	#region Private
	
	// Lexicon is an array of sequences (each sequence is an array of tokens)
	__lexicon_sequences = [];

	// exact_dict maps encoded full-sequence keys -> lexicon index
	__exact_dict = {};

	// ngram_dict maps encoded n-gram keys -> array of lexicon indices
	__ngram_dict = {};

	// Last input sequence used for search (for debugging / convenience)
	__input = [];

	// Hook value and score extractors for the base
	static __get_value = function(_entry_struct) {
		return _entry_struct.value; // full token sequence
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

	static __clear_lexicon = function() {
		__lexicon_sequences = [];
		__exact_dict        = {};
		__ngram_dict        = {};
		__input             = [];
		__clear_results();
	};

	// Encode a window of tokens into a stable string key.
	// We prefix with length and type markers ("s" for string, "n" for numeric)
	// to reduce collisions between types.
	static __encode_sequence_key = function(_tokens_array, _start_index, _length_context) {
		var _key = $"{_length_context}:";
		_key += string_join_ext("|", _tokens_array, _start_index, _length_context)
		return _key;
	};
	
	#endregion
}
