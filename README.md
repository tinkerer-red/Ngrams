# **GML N-Gram Models**

A lightweight, high-performance n-gram library for **GameMaker**, providing:

* **Fuzzy string search** (substring based)
* **Predictive string models** (character-level next-token prediction)
* **Fuzzy token-sequence search** (arbitrary value sequences)
* **Predictive token models** (token-level next-item prediction)

The system is fully written in GML.
It is designed for **speed**, with existing tools such as lexers, editors, auto-complete systems, fuzzy-search bars, or AI-like predictive input helpers.

---

## **Why You’d Want This**

### ✔ **Fast fuzzy search for UI tools**

Need an autocomplete bar?
Need to fuzzy-match against thousands of strings with low latency?
This library handles that with an optimized substring n-gram index.

### ✔ **Predictive text or token sequence modeling**

Useful for:

* IDE features (auto-suggest next token)
* Code assistant tools
* Typing prediction
* Procedural generation
* Language-model-style next-symbol prediction

### ✔ **Supports *arbitrary tokens***

Tokens can be:

* Strings
* Numbers
* Structs
* Pointers/handles
* Enums

Anything you can efficiently `string()` works.

### ✔ **Optimized for real-time use inside GameMaker**

* Avoids unnecessary allocations
* Uses length-based culling
* Max-result caps to prevent runaway expansions
* Separates training from querying
* All queries operate on pre-built n-gram dictionaries
* Zero dependency on external libraries

---

## **Included Modules**

| File                       | Purpose                                                 |
| -------------------------- | ------------------------------------------------------- |
| **NgramBase.gml**          | Shared base class for all n-gram models.                |
| **NgramStringFuzzy.gml**   | Fuzzy string matching using substring grams.            |
| **NgramStringPredict.gml** | Predictive single-character next-token model.           |
| **NgramTokenFuzzy.gml**    | Fuzzy matching for sequences of arbitrary tokens.       |
| **NgramTokenPredict.gml**  | Predictive next-token modeling for arbitrary sequences. |

---

# **Examples**

## **1. Fuzzy String Search (Autocomplete)**

```gml
var model = new NgramStringFuzzy(2, 5, 10, false);
model.train([ "apple", "applet", "application", "banana", "band", "bandana" ]);

model.search("appl");

var results = model.get_result_array();
var best    = model.get_top_value();

show_debug_message(best);  // "apple" or “applet”
```

---

## **2. Predict Next Character**

```gml
var model = new NgramStringPredict(1, 5, 10);
model.train([ "hello", "hey", "helium", "help", "helpful" ]);

model.predict("hel");

show_debug_message(model.get_top_value());  
// Likely “l” or “p”, depending on training data
```

---

## **3. Predict Next Token (Autocomplete for Code)**

```gml
var tok_ident   = "identifier";
var tok_assign  = "=";
var tok_number  = "number";
var tok_end     = ";";

var seq1 = [ tok_ident, tok_assign, tok_number, tok_end ];
var seq2 = [ tok_ident, tok_assign, tok_ident, tok_end ];

var model = new NgramTokenPredict(1, 4, 10);
model.train([ seq1, seq2 ]);

model.predict([ tok_ident, tok_assign ]);

var suggestion = model.get_top_value();
show_debug_message(suggestion);  // "number" or "identifier"
```

---

## **4. Fuzzy Match a Token Sequence**

```gml
var tok_if = "if";
var tok_lparen = "(";
var tok_rparen = ")";
var tok_block_open = "{";
var tok_block_close = "}";

var seqA = [ tok_if, tok_lparen, "x", tok_rparen, tok_block_open ];
var seqB = [ tok_if, tok_lparen, "y", tok_rparen, tok_block_open ];

var model = new NgramTokenFuzzy(1, 4, 10);
model.train([ seqA, seqB ]);

model.search([ tok_if, tok_lparen ]);

var result = model.get_top_value();
show_debug_message(result);
```

---

# **Design Notes**

* All models use **descending order n-gram scanning** for accuracy.
* Fuzzy models **cull impossible matches early** for performance.
* A result cap ensures that search never becomes O(N²).
* Predictive models weight longer contexts higher.
* Everything is stored in pure GML structs, making export/import trivial.

---

# **Installation**

1. Drop the `.gml` files into your project’s scripts folder or your preferred organization structure.
2. Call constructors directly:

```gml
var model = new NgramStringFuzzy();
```

3. Train → Query → Use.

---

# **Credits**

A large portion of the initial code foundation for substring fuzzy search originates from **Juju Adams**.

You can find his original fuzzy search experiments here:

> **[Ngram](https://github.com/JujuAdams/Ngram)**

Please support his open-source projects—his contributions to the community have been invaluable.
