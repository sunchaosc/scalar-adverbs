/* index.js — drop-in build
   - Practice: pure shuffle
   - Main trials: constrained shuffle with TWO constraints
       (1) ≤ 2 in a row from same category: "exp" vs "non"
       (2) ≤ 2 in a row with same object: "beaker" vs "flask"
   - Keeps your slide flow and logging (presentation_index, randomized_order)
*/

// ====== Helpers: category + object extraction + constraints ======

// Treat everything that's not "exp" as "non"
function categoryOf(stim) {
  return (stim.ExpFiller === "exp") ? "exp" : "non";
}

// Extract "beaker" or "flask" from a stim.
// Prefer explicit field if you have it (target/target_object).
// Fallback: parse from instruction3 text ("in the beaker"/"in the flask").
function objectOf(stim) {
  if (stim.target && (stim.target === "beaker" || stim.target === "flask")) {
    return stim.target;
  }
  if (stim.target_object && (stim.target_object === "beaker" || stim.target_object === "flask")) {
    return stim.target_object;
  }
  if (stim.instruction3 && typeof stim.instruction3 === "string") {
    const m = stim.instruction3.match(/\bin the (beaker|flask)\b/i);
    if (m) return m[1].toLowerCase();
  }
  return "unknown"; // won't bind a strong run constraint if not detectable
}

// Generic run-length checker using a key function
function violatesMaxRunByKey(seq, maxRun, keyFn) {
  let run = 1;
  for (let i = 1; i < seq.length; i++) {
    const prev = keyFn(seq[i - 1]);
    const cur  = keyFn(seq[i]);
    if (prev === cur) {
      run += 1;
      if (run > maxRun) return true;
    } else {
      run = 1;
    }
  }
  return false;
}

// For full sequences: test both constraints
function violatesEitherConstraint(seq, maxRunCategory, maxRunObject) {
  if (violatesMaxRunByKey(seq, maxRunCategory, categoryOf)) return true;
  if (violatesMaxRunByKey(seq, maxRunObject,  objectOf))    return true;
  return false;
}

// Build a sequence that respects BOTH constraints.
// Uses a fast naive shuffle pass, then a greedy randomized constructor with backoffs.
function constrainedShuffleStims(stims, maxRunCategory = 2, maxRunObject = 2, maxTries = 2000) {
  const expPool0 = stims.filter(s => categoryOf(s) === "exp");
  const nonPool0 = stims.filter(s => categoryOf(s) !== "exp");

  // Fast path: try naive shuffles first
  for (let t = 0; t < 50; t++) {
    const cand = _.shuffle(stims);
    if (!violatesEitherConstraint(cand, maxRunCategory, maxRunObject)) return cand;
  }

  // Helper: check incremental violation if we append 'cand'
  function wouldViolate(seq, cand) {
    // Quick tail checks only (O(run))
    // 1) category tail
    let r = 1;
    for (let i = seq.length - 1; i >= 0; i--) {
      if (categoryOf(seq[i]) === categoryOf(cand)) r++; else break;
    }
    if (r > maxRunCategory) return true;

    // 2) object tail
    r = 1;
    for (let i = seq.length - 1; i >= 0; i--) {
      if (objectOf(seq[i]) === objectOf(cand)) r++; else break;
    }
    if (r > maxRunObject) return true;

    return false;
  }

  // Greedy randomized constructor
  let best = null;
  for (let t = 0; t < maxTries; t++) {
    let e = _.shuffle(expPool0.slice());
    let n = _.shuffle(nonPool0.slice());

    let seq = [];
    let lastCat = null;
    let catRun  = 0;

    while (e.length || n.length) {
      // Which category is allowed by category constraint?
      let allowedCats = [];
      if (lastCat === "exp" && catRun >= maxRunCategory) {
        allowedCats = n.length ? ["non"] : ["exp"];
      } else if (lastCat === "non" && catRun >= maxRunCategory) {
        allowedCats = e.length ? ["exp"] : ["non"];
      } else {
        if (e.length) allowedCats.push("exp");
        if (n.length) allowedCats.push("non");
      }

      // Weighted pick by remaining pool sizes if both allowed
      const pickCategory = () => {
        if (allowedCats.length === 2) {
          const re = e.length, rn = n.length;
          return (Math.random() < re / (re + rn)) ? "exp" : "non";
        }
        return allowedCats[0];
      };

      let triedCats = new Set();
      let placed = false;

      // Try allowed categories, find an item that doesn't violate either constraint
      while (!placed && triedCats.size < allowedCats.length) {
        const cat = pickCategory();
        triedCats.add(cat);

        let pool = (cat === "exp") ? e : n;
        if (!pool.length) continue;

        let idxs = _.shuffle(pool.map((_, i) => i));
        let pickIdx = -1;
        for (const i of idxs) {
          if (!wouldViolate(seq, pool[i])) { pickIdx = i; break; }
        }

        if (pickIdx >= 0) {
          const stim = pool.splice(pickIdx, 1)[0];
          seq.push(stim);
          if (lastCat === cat) catRun += 1; else { lastCat = cat; catRun = 1; }
          placed = true;
          break;
        }
      }

      // If nothing fit, place any allowed item (least-bad backoff)
      if (!placed) {
        const cat = allowedCats[0] || (e.length ? "exp" : "non");
        let pool = (cat === "exp") ? e : n;
        const i = Math.floor(Math.random() * pool.length);
        const stim = pool.splice(i, 1)[0];
        seq.push(stim);
        if (lastCat === cat) catRun += 1; else { lastCat = cat; catRun = 1; }
      }
    }

    if (!violatesEitherConstraint(seq, maxRunCategory, maxRunObject)) return seq;
    if (!best || Math.random() < 0.3) best = seq; // keep near-best fallback
  }

  console.warn("constrainedShuffleStims: fell back to near-best sequence (two-constraint mode)");
  return best || _.shuffle(stims);
}

// ====== Slides ======
function make_slides(f) {
  var slides = {};

  slides.i0 = slide({
    name : "i0",
    start: function() {
      exp.startT = Date.now();
    }
  });

  slides.instructions = slide({
    name : "instructions",
    button : function() {
      exp.go();
    }
  });

  // ---------- PRACTICE ----------
  slides.practice = slide({
    name : "practice",
    start: function(){
      exp.counter = 0;
      $(".err").hide();
      $(".correct").hide();
    },
    present: exp.practice_shuffled,
    present_handle : function(stim) {

      exp.selection_array=[];
      this.stim = stim;
      $(".err").hide();
      $(".correct").hide();
      $(".grid-container").show();

      var correctAns = this.stim.correctAns;
      console.log(correctAns)

      const instruction = this.stim.instruction1;
      let words = instruction.split("|");
      let init_instruction = words[0] + " ..."; // The|
      let instruction1 = words[0] + " " + words[1] + " ..."; // The| arrow|
      let instruction2 = words[0] + " " + words[1] + " " + words[2] + " ...";
      let instruction3 = words[0] + " " + words[1] + " " + words[2] + " " + words[3];

      const instruction_array = [instruction1, instruction2, instruction3];

      $(".sentence").html(init_instruction);

      var loc1_img = '<img src="images/'+this.stim.location1+'.png"  class="left">';
      $(".loc1").html(loc1_img);
      var loc2_img = '<img src="images/'+this.stim.location2+'.png"  class="center">';
      $(".loc2").html(loc2_img);
      var loc3_img = '<img src="images/'+this.stim.location3+'.png"  class="center">';
      $(".loc3").html(loc3_img);
      var loc4_img = '<img src="images/'+this.stim.location4+'.png"  class="center">';
      $(".loc4").html(loc4_img);
      var loc5_img = '<img src="images/loc5.png" style="height:50px" class="center">';
      $(".loc5").html(loc5_img);

      $(".loc").bind("click",function(e){
        $(".err").hide();
        $(".correct").hide();
        e.preventDefault();
        var loc = $(this).data().loc

        if (exp.counter==3){
          if (loc === correctAns) {
            $(".correct").show();
            exp.counter++;  // allow advance on next click
          } else {
            $(".err").show();
          }
        } else if (exp.counter>3){
          exp.selection_array.push(loc)
          exp.counter = 0;
          $(".loc").unbind('click')
          _s.button();
        } else {
          exp.selection_array.push(loc)
          $(".sentence").html(instruction_array[exp.counter])
          exp.counter++;
        }
      });
    },

    button : function() {
      console.log("Location array => ",exp.selection_array)
      this.log_responses();
      _stream.apply(this);
    },

    log_responses : function() {
      exp.data_trials.push({
        "displayID"   : this.stim.displayID,
        "ExpFiller"   : this.stim.ExpFiller,
        "location1"   : this.stim.location1,
        "location2"   : this.stim.location2,
        "location3"   : this.stim.location3,
        "location4"   : this.stim.location4,
        "condition"   : this.stim.condition,
        "target"      : this.stim.target,
        "competitor"  : this.stim.competitor,
        "instruction1": this.stim.instruction1,   // practice uses instruction1
        "correctAns"  : this.stim.correctAns,
        "response"    : exp.selection_array
      });
    }
  });

  slides.afterpractice = slide({
    name : "afterpractice",
    button : function() {
      exp.go();
    }
  });

  // ---------- MAIN TRIALS ----------
  slides.trial = slide({
    name : "trial",
    present: exp.stims_shuffled,
    start: function(){
      exp.counter = 0;
    },
    present_handle : function(stim) {
      exp.selection_array=[];
      exp.time_array=[];
      exp.trial_start = Date.now();

      $(".err").hide();
      $(".grid-container").show();

      this.stim = stim;

      // capture 1-based presentation index for THIS trial
      this.presentation_index = (exp.trial_index || 0) + 1;
      exp.trial_index = this.presentation_index;

      const instruction = stim.instruction3;
      let words = instruction.split("|");
      let init_instruction = words[0] + " ..."; // The
      let instruction1 = words[0] + " " + words[1] + " ..."; // The| arrow|
      let instruction2 = words[0] + " " + words[1] + " " + words[2] + " ...";
      let instruction3 = words[0] + " " + words[1] + " " + words[2] + " " + words[3];

      const instruction_array = [instruction1, instruction2, instruction3];

      $(".instruction").html(init_instruction);

      var loc1_img = '<img src="images/'+stim.location1+'.png"  class="left">';
      $(".loc1").html(loc1_img);
      var loc2_img = '<img src="images/'+stim.location2+'.png"  class="center">';
      $(".loc2").html(loc2_img);
      var loc3_img = '<img src="images/'+stim.location3+'.png"  class="center">';
      $(".loc3").html(loc3_img);
      var loc4_img = '<img src="images/'+stim.location4+'.png"  class="center">';
      $(".loc4").html(loc4_img);
      var loc5_img = '<img src="images/loc5.png" style="height:50px" class="center">';
      $(".loc5").html(loc5_img);

      $(".loc").bind("click",function(e){
        e.preventDefault();
        if (exp.counter>2){
          exp.selection_array.push($(this).data().loc)
          exp.time_array.push(Date.now()-exp.trial_start)
          exp.counter = 0;
          $(".loc").unbind('click')
          _s.button();
        } else {
          exp.selection_array.push($(this).data().loc)
          exp.time_array.push(Date.now()-exp.trial_start)
          $(".instruction").html(instruction_array[exp.counter])
          exp.counter++;
        }
      });

    },

    button : function() {
      console.log("Location array => ",exp.selection_array)
      console.log("Time array => ",exp.time_array)
      this.log_responses();
      _stream.apply(this);
    },

    log_responses : function() {
      exp.data_trials.push({
        "displayID"     : this.stim.displayID,
        "location1"     : this.stim.location1,
        "location2"     : this.stim.location2,
        "location3"     : this.stim.location3,
        "location4"     : this.stim.location4,
        "target"        : this.stim.target,
        "competitor"    : this.stim.competitor,
        "condition"     : this.stim.condition,     // from CSV 'adj'
        "ExpFiller"     : this.stim.ExpFiller,
        "correctAns"    : this.stim.correctAns,
        "list"          : this.stim.list,
        "instruction3"  : this.stim.instruction3,
        "response_times": exp.time_array,
        "response"      : exp.selection_array,
        "trial_in_list" : this.stim.trial_in_list,
        "presentation_index": this.presentation_index
      });
    }
  });

  slides.subj_info =  slide({
    name : "subj_info",
    submit : function(e){
      exp.subj_data = {
        prolificID: $("#ProlificID").val(),
        gender : $("#gender").val(),
        age : $("#age").val(),
        language : $("#language").val(),
        asses : $('input[name="assess"]:checked').val(),
        problems: $("#problems").val(),
        comments : $("#comments").val(),
      };
      exp.go();
    }
  });

  slides.thanks = slide({
    name : "thanks",
    start : function() {
      exp.data= {
        "trials" : exp.data_trials,
        "catch_trials" : exp.catch_trials,
        "system" : exp.system,
        "subject_information" : exp.subj_data,
        "time_in_minutes" : (Date.now() - exp.startT)/60000,
        "randomized_order"  : exp.randomized_order
      };
      proliferate.submit(exp.data);
    }
  });

  return slides;
}

// ====== Init ======
function init() {
  exp.trials = [];
  exp.catch_trials = [];

  exp.system = {
    Browser : BrowserDetect.browser,
    OS : BrowserDetect.OS,
    screenH: screen.height,
    screenUH: exp.height,
    screenW: screen.width,
    screenUW: exp.width
  };

  // Practice: pure uniform shuffle
  exp.practice_shuffled = _.shuffle(exp.practice);

  // Main trials: constrained shuffle
  //   - max 2 consecutive "exp" or "non"
  //   - max 2 consecutive "beaker" or "flask" (from target/instruction3)
  exp.stims_shuffled = constrainedShuffleStims(exp.stims, /*maxRunCategory*/ 2, /*maxRunObject*/ 2);

  // Store full order for record (by displayID if available)
  exp.randomized_order = exp.stims_shuffled.map(s => s.displayID || s.item_id || "NA");

  // blocks of the experiment:
  exp.structure=["i0", "instructions", "practice", "afterpractice", "trial", 'subj_info', 'thanks'];

  exp.data_trials = [];
  // make corresponding slides:
  exp.slides = make_slides(exp);

  exp.nQs = utils.get_exp_length();

  $('.slide').hide();

  $("#start_button").on("click", function () { exp.go(); });
  exp.go(); // show first slide
}
