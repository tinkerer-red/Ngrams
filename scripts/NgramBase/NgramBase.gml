#region jsDoc
/// @func  NgramBase()
/// @desc  Base constructor for n-gram handlers (string/token, fuzzy/predict).
///        Manages shared configuration and result handling.
/// @param {Real} _n_gram_min   Minimum n-gram size (or order).
/// @param {Real} _n_gram_max   Maximum n-gram size (or order).
/// @param {Real} _max_results  Maximum number of results to expose.
/// @returns {Struct.NgramBase}
#endregion
function NgramBase(_n_gram_min, _n_gram_max, _max_results) constructor {
	nGramMin   = max(1, _n_gram_min);
	nGramMax   = max(nGramMin, _n_gram_max);
	maxResults = (_max_results > 0) ? _max_results : 10;
	
	__result_array       = [];
	__result_array_dirty = true;
	
	__value_array        = [];
	__score_array        = [];
	
	// Hooks to be set by children
	// __get_value(_entry) -> primary value (string or token id)
	// __get_score(_entry) -> numeric score (strength / probability)
	// __compare(_a, _b)   -> comparator for array_sort
	static __get_value = undefined;
	static __get_score = undefined;
	static __compare   = undefined;
	
	// Default train/load/export (children can override)
	#region jsDoc
	/// @func  train()
	/// @desc  Base train method. Children override to build gram structures.
	/// @param {Any} _data
	/// @returns {Struct.NgramBase}
	#endregion
	static train = function(_data) {
		// No-op by default
		return self;
	};
	
	#region jsDoc
	/// @func  export()
	/// @desc  Base export method. Children override to serialize model data.
	/// @returns {Struct}
	#endregion
	static export = function() {
		var _model_struct = {
			type        : "NgramBase",
			n_gram_min  : nGramMin,
			n_gram_max  : nGramMax,
			max_results : maxResults
		};
		return _model_struct;
	};
	
	#region jsDoc
	/// @func  load()
	/// @desc  Base load method. Children override and may call this to restore
	///        shared config.
	/// @param {Struct} _model_struct
	/// @returns {Struct.NgramBase}
	#endregion
	static load = function(_model_struct) {
		nGramMin   = _model_struct[$ "n_gram_min"]  ? max(1, _model_struct.n_gram_min)        : nGramMin;
		nGramMax   = _model_struct[$ "n_gram_max"]  ? max(nGramMin, _model_struct.n_gram_max) : nGramMax;
		maxResults = _model_struct[$ "max_results"] ? max(1, _model_struct.max_results)       : maxResults;
		
		__clear_results();
		return self;
	};
	
	// Internal helpers for results
	
	static __clear_results = function() {
		array_resize(__result_array, 0);
		array_resize(__value_array, 0);
		array_resize(__score_array, 0);

		__result_array_dirty = true;
	};
	
	static __mark_results_dirty = function() {
		__result_array_dirty = true;
	};
	
	static __finalize_results = function() {
		if (!__result_array_dirty) {
			return;
		}
		
		var _length_result = array_length(__result_array);
		if (_length_result > 1) {
			if (is_undefined(__compare)) {
				array_sort(__result_array, function(_entry_a, _entry_b) {
					var _score_a = (variable_struct_exists(_entry_a, "score")) ? _entry_a.score : 0;
					var _score_b = (variable_struct_exists(_entry_b, "score")) ? _entry_b.score : 0;
					
					var _difference = _score_b - _score_a;
					if (_difference > 0) return 1;
					if (_difference < 0) return -1;
					return 0;
				});
			}
			else {
				array_sort(__result_array, __compare);
			}
		}
		
		if (_length_result > maxResults) {
			array_resize(__result_array, maxResults);
		}
		
		var _length_result = array_length(__result_array);
		var _i=0; repeat(_length_result) {
			var _entry_struct = __result_array[_i];
			__value_array[_i] = __get_value(_entry_struct);
			__score_array[_i] = __get_score(_entry_struct);
		_i++}
		
		__result_array_dirty = false;
	};
	
	// Shared public helpers
	
	#region jsDoc
	/// @func  get_result_array()
	/// @desc  Returns the raw array of result entries (structs).
	/// @returns {Array<Struct>}
	#endregion
	static get_result_array = function() {
		__finalize_results();
		return __result_array;
	};
	
	#region jsDoc
	/// @func  get_value_array()
	/// @desc  Returns an array of primary values (tokens or strings),
	///        extracted using __get_value().
	/// @returns {Array<Any>}
	#endregion
	static get_value_array = function() {
		__finalize_results();
		return __value_array;
	};
	
	#region jsDoc
	/// @func  get_score_array()
	/// @desc  Returns an array of scores (strength, probability, etc),
	///        extracted using __get_score().
	/// @returns {Array<Real>}
	#endregion
	static get_score_array = function() {
		__finalize_results();
		return __score_array;
	};
	
	#region jsDoc
	/// @func  get_top_result()
	/// @desc  Returns the top result entry struct, or undefined if none.
	/// @returns {Struct|Undefined}
	#endregion
	static get_top_result = function() {
		__finalize_results();
	
		var _length_result = array_length(__result_array);
		if (_length_result <= 0) {
			return undefined;
		}
	
		return __result_array[0];
	};

	#region jsDoc
	/// @func  get_top_value()
	/// @desc  Returns the primary value (string or token id) of the top result,
	///        or undefined if there are no results.
	/// @returns {Any|Undefined}
	#endregion
	static get_top_value = function() {
		__finalize_results();
	
		var _length_result = array_length(__result_array);
		if (_length_result <= 0) {
			return undefined;
		}
	
		var _top_entry = __result_array[0];
	
		if (__get_value != undefined) {
			return __get_value(_top_entry);
		}
	
		return _top_entry;
	};

	#region jsDoc
	/// @func  get_top_score()
	/// @desc  Returns the score (strength/probability/etc) of the top result,
	///        or 0 if there are no results.
	/// @returns {Real}
	#endregion
	static get_top_score = function() {
		__finalize_results();
	
		var _length_result = array_length(__result_array);
		if (_length_result <= 0) {
			return 0;
		}
	
		var _top_entry = __result_array[0];
	
		if (__get_score != undefined) {
			return __get_score(_top_entry);
		}
	
		if (variable_struct_exists(_top_entry, "score")) {
			return _top_entry.score;
		}
	
		return 0;
	};

}


