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
function NgramTokenFuzzy(_n_gram_min=3, _n_gram_max=5, _max_results=10)
	: NgramBase(_n_gram_min, _n_gram_max, _max_results) constructor {
	
	#region jsDoc
	/// @func  train()
	/// @desc  Train the fuzzy model from a lexicon array of token sequences.
	///        Each element of _tokens_array should be an Array of tokens.
	///        Builds token n-grams for orders between n_gram_min and n_gram_max.
	///        N-gram buckets store a numeric hash per sequence for faster lookup.
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

					// Identity string for the whole sequence
					var _identity_key = __encode_sequence_key(_sequence, 0, _seq_length);

					// Hash for this identity string
					var _seq_hash = variable_get_hash(_identity_key);

					// Hash lookup helper: hash -> identity string
					__hash_to_key[$ _identity_key] = _identity_key;

					// Identity to sequence mapping
					__identity_to_sequence[$ _identity_key] = _sequence;

					// Exact match dictionary: identity -> hash
					__exact_dict[$ _identity_key] = _seq_hash;

					// Build n-grams for this sequence
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
								var _hash_array = __ngram_dict[$ _key];
								if (!is_array(_hash_array)) {
									_hash_array = [ _seq_hash ];
									__ngram_dict[$ _key] = _hash_array;
								}
								else {
									if (!array_contains(_hash_array, _seq_hash)) {
										array_push(_hash_array, _seq_hash);
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
			type                 : "NgramTokenFuzzy",
			n_gram_min           : nGramMin,
			n_gram_max           : nGramMax,
			max_results          : maxResults,
			lexicon_sequences    : __lexicon_sequences,
			exact_dict           : __exact_dict,
			ngram_dict           : __ngram_dict,
			hash_to_key          : __hash_to_key,
			identity_to_sequence : __identity_to_sequence
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

		__lexicon_sequences    = (_model_struct[$ "lexicon_sequences"])    ? _model_struct.lexicon_sequences    : [];
		__exact_dict           = (_model_struct[$ "exact_dict"])           ? _model_struct.exact_dict           : {};
		__ngram_dict           = (_model_struct[$ "ngram_dict"])           ? _model_struct.ngram_dict           : {};
		__hash_to_key          = (_model_struct[$ "hash_to_key"])          ? _model_struct.hash_to_key          : {};
		__identity_to_sequence = (_model_struct[$ "identity_to_sequence"]) ? _model_struct.identity_to_sequence : {};

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
	///        This variant:
	///        - Searches from the largest n-grams downwards
	///        - Only creates new candidates while candidate_count < maxResults
	///        - Continues to accumulate strength for existing entries
	///        - Uses numeric sequence hashes in the n-gram buckets for faster
	///          lookup through struct_get_from_hash().
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

		var _result_dict      = {};
		var _result_array_ref = __result_array;

		var _input_length = array_length(_input_tokens);

		// Exact match check
		if (_input_length > 0) {
			var _full_identity = __encode_sequence_key(_input_tokens, 0, _input_length);
			var _exact_hash    = __exact_dict[$ _full_identity];

			if (_exact_hash != undefined) {
				var _identity_key = struct_get_from_hash(__hash_to_key, _exact_hash);
				if (_identity_key != undefined) {
					var _seq_exact = __identity_to_sequence[$ _identity_key];

					var _exact_entry = {
						value    : _seq_exact,
						strength : infinity
					};

					_result_dict[$ _identity_key] = _exact_entry;
					array_push(_result_array_ref, _exact_entry);
				}
			}
		}

		if (_input_length <= 0) {
			__mark_results_dirty();
			return self;
		}

		var _local_min = nGramMin;
		var _local_max = min(nGramMax, _input_length);

		if (_local_min > _local_max) {
			_local_min = _local_max;
		}

		var _max_results = maxResults;
		var _found_count = array_length(_result_array_ref);
		
		var _used_grams_struct = {};
		
		// Search from largest n-gram down to smallest.
		var _current_size = _local_max;

		var _range_length = (_local_max - _local_min) + 1;
		var _range_index  = 0;
		repeat (_range_length) {
			var _max_start = _input_length - _current_size;

			var _start_index = 0;
			repeat (_max_start + 1) {
				var _key = __encode_sequence_key(_input_tokens, _start_index, _current_size);
				
				if (struct_exists(_used_grams_struct, _key)) {
					_hash_index++;
					continue;
				}
				else {
					struct_set(_used_grams_struct, _key, true);
				}
				
				var _hash_array = __ngram_dict[$ _key];

				if (is_array(_hash_array)) {
					var _hash_length = array_length(_hash_array);
					var _hash_index  = 0;

					repeat (_hash_length) {
						var _seq_hash = _hash_array[_hash_index];
						
						// Check for existing candidate via hash
						var _existing_entry = struct_get_from_hash(_result_dict, _seq_hash);

						if (_existing_entry == undefined) {
							if (_found_count < _max_results) {
								var _identity_key = struct_get_from_hash(__hash_to_key, _seq_hash);
								if (_identity_key != undefined) {
									var _seq_value = __identity_to_sequence[$ _identity_key];

									var _new_entry = {
										value    : _seq_value,
										strength : 1
									};

									_result_dict[$ _identity_key] = _new_entry;
									array_push(_result_array_ref, _new_entry);
									_found_count++;
								}
							}
						}
						else {
							var _weight = _current_size*_current_size;
							_existing_entry.strength += _weight;
						}

						_hash_index++;
					}
				}

				_start_index++;
			}

			_current_size--;
			_range_index++;
		}
		
		
		// Normalize strengths to [0..1] after all counts are accumulated.
		// If an exact match (infinity) exists, it gets strength=1 and all
		// other entries are forced to 0. Otherwise, each strength is divided
		// by the total so that all strengths sum to 1.
		var _length_result = array_length(_result_array_ref);
		if (_length_result > 0) {
			var _has_infinity    = false;
			var _total_strength  = 0;
			var _index_result    = 0;
			
			// First pass: detect infinity and sum finite strengths
			repeat (_length_result) {
				var _entry_struct = _result_array_ref[_index_result];
				if (_entry_struct.strength == infinity) {
					_has_infinity = true;
				}
				else {
					_total_strength += _entry_struct.strength;
				}
				_index_result++;
			}
		
			_index_result = 0;
			if (_has_infinity) {
				// Exact match dominates: 1 for that entry, 0 for all others
				repeat (_length_result) {
					var _entry_struct = _result_array_ref[_index_result];
					_entry_struct.strength = (_entry_struct.strength == infinity) ? 1 : 0;
					_index_result++;
				}
			}
			else if (_total_strength > 0) {
				var _inv_total = 1 / _total_strength;
				repeat (_length_result) {
					var _entry_struct = _result_array_ref[_index_result];
					_entry_struct.strength = _entry_struct.strength * _inv_total;
					_index_result++;
				}
			}
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

	// exact_dict maps full sequence identity strings -> numeric hash
	__exact_dict = {};

	// ngram_dict maps encoded n-gram keys -> array of sequence hashes
	__ngram_dict = {};

	// hash_to_key maps hash -> identity string (via struct_get_from_hash)
	__hash_to_key = {};

	// identity_to_sequence maps identity string -> token array
	__identity_to_sequence = {};

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
		return sign(_difference);
	};

	static __clear_lexicon = function() {
		__lexicon_sequences    = [];
		__exact_dict           = {};
		__ngram_dict           = {};
		__hash_to_key          = {};
		__identity_to_sequence = {};
		__input                = [];
		__clear_results();
	};

	// Encode a window of tokens into a stable string key.
	// Uses string_join_ext to keep things simple and consistent.
	static __encode_sequence_key = function(_tokens_array, _start_index, _length_context) {
		var _key = $"{_length_context}:";
		_key += string_join_ext("|", _tokens_array, _start_index, _length_context);
		return _key;
	};
	
	#endregion
}
