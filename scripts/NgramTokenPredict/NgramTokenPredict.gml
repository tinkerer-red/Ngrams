#region jsDoc
/// @func  NgramTokenPredict()
/// @desc  Predictive n-gram model for arbitrary tokens. Trains on sequences of
///        tokens and predicts the most likely next token given a token prefix.
///        Uses variable-order n-grams between n_gram_min and n_gram_max.
/// @param {Real} _n_gram_min  : Minimum n-gram order (context length).
/// @param {Real} _n_gram_max  : Maximum n-gram order (context length).
/// @param {Real} _max_results : Maximum number of prediction results.
/// @returns {Struct.NgramTokenPredict}
#endregion
function NgramTokenPredict(_n_gram_min=3, _n_gram_max=25, _max_results=10)
	: NgramBase(_n_gram_min, _n_gram_max, _max_results) constructor {
	
	// Encode a context window of tokens into a stable string key
	// NOTE: we preserve the actual tokens separately; this key is
	// only used for indexing the context dictionary.
	static __encode_context_key = function(_tokens_array, _start_index, _length) {
		var _key = $"{_length}:";
		_key += string_join_ext("|", _tokens_array, _start_index, _length)
		return _key;
	};

	// INTERNAL: add a single observation (context_key -> next_token)
	static __add_observation = function(_context_key, _next_token) {
		var _entry_struct = __context_dict[$ _context_key];
		if (_entry_struct == undefined) {
			_entry_struct = {
				entries: [],
				total  : 0
			};
			__context_dict[$ _context_key] = _entry_struct;
		}

		var _entries_array  = _entry_struct.entries;
		var _entries_length = array_length(_entries_array);

		var _index_entry = 0;
		var _found_index = -1;

		// Find existing entry for this token
		repeat(_entries_length) {
			var _entry = _entries_array[_index_entry];
			if (_entry.token == _next_token) {
				_found_index = _index_entry;
				break;
			}
			_index_entry++;
		}

		if (_found_index >= 0) {
			var _existing = _entries_array[_found_index];
			_existing.count += 1;
			_entries_array[_found_index] = _existing;
		}
		else {
			var _new_entry = {
				token: _next_token,
				count: 1
			};
			array_push(_entries_array, _new_entry);
		}

		_entry_struct.entries = _entries_array;
		_entry_struct.total  += 1;
	};

	// TRAIN API

	#region jsDoc
	/// @func  train()
	/// @desc  Train the predictive model from an array of token sequences.
	///        Each element of _tokens_array should be an Array of tokens.
	///        For each sequence, n-grams (orders from n_gram_min to n_gram_max)
	///        are used as contexts, and the next token occurrences are counted.
	/// @param {Array<Array>} _tokens_array
	/// @returns {Struct.NgramTokenPredict}
	#endregion
	static train = function(_tokens_array) {
		__clear_model();

		var _outer_length = array_length(_tokens_array);
		var _outer_index  = 0;

		while (_outer_index < _outer_length) {
			var _sequence = _tokens_array[_outer_index];

			if (is_array(_sequence)) {
				var _seq_length = array_length(_sequence);

				// Need at least 2 tokens to have context + next
				if (_seq_length > 1) {
					var _position_index = 1; // 0-based index of "next token"

					while (_position_index < _seq_length) {
						var _max_context  = min(nGramMax, _position_index);
						var _context_size = nGramMin;

						while (_context_size <= _max_context) {
							var _context_start_index = _position_index - _context_size;
							var _context_key = __encode_context_key(_sequence, _context_start_index, _context_size);

							var _next_token = _sequence[_position_index];

							__add_observation(_context_key, _next_token);

							_context_size++;
						}

						_position_index++;
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
	/// @desc  Export the predictive token model as a struct suitable for json_encode().
	/// @returns {Struct}
	#endregion
	static export = function() {
		var _model_struct = {
			type        : "NgramTokenPredict",
			n_gram_min  : nGramMin,
			n_gram_max  : nGramMax,
			max_results : maxResults,
			context_dict: __context_dict
		};
		return _model_struct;
	};

	#region jsDoc
	/// @func  load()
	/// @desc  Load a predictive token model from an exported struct.
	/// @param {Struct} _model_struct
	/// @returns {Struct.NgramTokenPredict}
	#endregion
	static load = function(_model_struct) {
		// Shared config from base
		static __parent_load = NgramBase.load;
		__parent_load(_model_struct);

		__context_dict = (_model_struct[$ "context_dict"]) ? _model_struct.context_dict : {};

		__input = [];
		__clear_results();
		return self;
	};

	// PREDICTION

	#region jsDoc
	/// @func  predict()
	/// @desc  Predict the next token(s) for the given token prefix sequence.
	///        Populates the internal result arrays with structs:
	///        {
	///            value       : Any (token),
	///            probability : Real (0..1),
	///        }
	/// @param {Array} _prefix_tokens
	/// @returns {Struct.NgramTokenPredict}
	#endregion
	static predict = function(_prefix_tokens) {
		__clear_results();
		__input = _prefix_tokens;

		if (!is_array(_prefix_tokens)) {
			__mark_results_dirty();
			return self;
		}

		var _prefix_length = array_length(_prefix_tokens);
		if (_prefix_length <= 0) {
			__mark_results_dirty();
			return self;
		}

		// Aggregate scores from all matching context orders
		var _score_entries = [];
		var _weight_sum    = 0;

		var _order_value = nGramMin;
		while (_order_value <= nGramMax) {
			if (_prefix_length >= _order_value) {
				var _context_start_index = _prefix_length - _order_value;
				var _context_key = __encode_context_key(_prefix_tokens, _context_start_index, _order_value);

				var _entry_struct = __context_dict[$ _context_key];

				if (_entry_struct != undefined && _entry_struct.total > 0) {
					var _entries_array = _entry_struct.entries;
					var _total_count   = _entry_struct.total;

					var _weight_value = _order_value; // longer context -> higher weight
					_weight_sum += _weight_value;

					var _entries_length = array_length(_entries_array);
					var _entry_index    = 0;

					while (_entry_index < _entries_length) {
						var _ctx_entry    = _entries_array[_entry_index];
						var _ctx_token    = _ctx_entry.token;
						var _ctx_count    = _ctx_entry.count;
						var _prob_value   = _ctx_count / _total_count;
						var _weighted_val = _prob_value * _weight_value;

						// Accumulate into _score_entries (per unique token)
						var _score_length = array_length(_score_entries);
						var _score_index  = 0;
						var _found_index  = -1;

						repeat(_score_length) {
							var _score_entry = _score_entries[_score_index];
							if (_score_entry.token == _ctx_token) {
								_found_index = _score_index;
								break;
							}
							_score_index++;
						}

						if (_found_index >= 0) {
							var _existing_score_entry = _score_entries[_found_index];
							_existing_score_entry.score += _weighted_val;
							_score_entries[_found_index] = _existing_score_entry;
						}
						else {
							var _new_score_entry = {
								token: _ctx_token,
								score: _weighted_val
							};
							array_push(_score_entries, _new_score_entry);
						}

						_entry_index++;
					}
				}
			}

			_order_value++;
		}

		// Convert scores into result entries
		if (_weight_sum > 0) {
			var _score_length = array_length(_score_entries);
			var _score_index  = 0;

			while (_score_index < _score_length) {
				var _score_entry = _score_entries[_score_index];
				var _token_value = _score_entry.token;
				var _score_value = _score_entry.score;

				var _probability = _score_value / _weight_sum;

				var _entry = {
					value      : _token_value,
					probability: _probability,
				};

				array_push(__result_array, _entry);

				_score_index++;
			}
		}

		__finalize_results();
		return self;
	};

	#region jsDoc
	/// @func  predict_best()
	/// @desc  Convenience helper. Predicts next tokens for the given prefix
	///        and returns only the most likely next token, or undefined
	///        if there are no results.
	/// @param {Array} _prefix_tokens
	/// @returns {Any|Undefined}
	#endregion
	static predict_best = function(_prefix_tokens) {
		predict(_prefix_tokens);
		return get_top_value();
	};
	
	#region Private
	
	// context_key (string) -> { entries: [ { token, count } ], total: Real }
	__context_dict = {};

	// Last prefix used (for introspection / debugging)
	__input = [];
	
	// Hook value and score extractors for the base
	static __get_value = function(_entry_struct) {
		return _entry_struct.value; // predicted token
	};

	static __get_score = function(_entry_struct) {
		return _entry_struct.probability; // 0..1
	};

	static __compare = function(_entry_a, _entry_b) {
		var _difference = _entry_b.probability - _entry_a.probability;
		return sign(_difference);
	};

	static __clear_model = function() {
		__context_dict = {};
		__input = [];
		__clear_results();
	};
	
	#endregion
}
