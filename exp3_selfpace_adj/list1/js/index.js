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
      exp.go(); //use exp.go() if and only if there is no "present" data.
    }
  });

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
            }
            else {
              $(".err").show();
              // stay at same counter, do NOT advance
              // participant must click the correct object to continue
            }
          }
                    else if (exp.counter>3){
            exp.selection_array.push(loc)
            exp.counter = 0;
            $(".loc").unbind('click')
            _s.button();
          }
         else {
            exp.selection_array.push(loc)
            $(".sentence").html(instruction_array[exp.counter])
            exp.counter++;
            }
         }
       );
    },

    button : function() {
      console.log("Location array => ",exp.selection_array)
      this.log_responses();
      _stream.apply(this); /* use _stream.apply(this); if and only if there is
      "present" data. (and only *after* responses are logged) */
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
      exp.go(); //use exp.go() if and only if there is no "present" data.
    }
  });

  slides.trial = slide({
    name : "trial",
    present: exp.stims_shuffled, //every element in exp.stims is passed to present_handle one by one as 'stim'
    start: function(){
      exp.counter = 0;

    },
    present_handle : function(stim) {
      exp.selection_array=[];
      exp.time_array=[];
      exp.trial_start = Date.now();
      console.log("time:"+(Date.now()-exp.trial_start))

      $(".err").hide();
      $(".grid-container").show();

      this.stim = stim; // store this information in the slide so you can record it later

      // --- capture presentation index for THIS trial ---
      this.presentation_index = (exp.trial_index || 0) + 1; // 1-based
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
          console.log("time:" + (Date.now()-exp.trial_start))
          exp.counter = 0;
          $(".loc").unbind('click')
          _s.button();
        } else {
          exp.selection_array.push($(this).data().loc)
          exp.time_array.push(Date.now()-exp.trial_start)
          console.log("time:" + (Date.now()-exp.trial_start))
          $(".instruction").html(instruction_array[exp.counter])
          exp.counter++;
        }
       });

    },

    button : function() {
      console.log("Location array => ",exp.selection_array)
      console.log("Time array => ",exp.time_array)
      this.log_responses();
      _stream.apply(this); /* use _stream.apply(this); if and only if there is
      "present" data. (and only *after* responses are logged) */

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
      "condition"     : this.stim.condition,     // from CSV 'adj' in your build
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
      exp.go(); //use exp.go() if and only if there is no "present" data.
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

// Treat everything that's not "exp" as "non"
function categoryOf(stim) {
  return (stim.ExpFiller === "exp") ? "exp" : "non";
}

// Verify a sequence never has > maxRun of the same exp/non category
function violatesMaxRun(seq, maxRun) {
  let run = 1;
  for (let i = 1; i < seq.length; i++) {
    const prev = categoryOf(seq[i - 1]);
    const cur  = categoryOf(seq[i]);
    if (cur === prev) {
      run += 1;
      if (run > maxRun) return true;
    } else {
      run = 1;
    }
  }
  return false;
}

// Build a sequence with maxRun constraint between "exp" and "non"
function constrainedShuffleStims(stims, maxRun = 2, maxTries = 2000) {
  // Split pools
  let expPool = stims.filter(s => s.ExpFiller === "exp");
  let nonPool = stims.filter(s => s.ExpFiller !== "exp");

  // Fast path: try a few naive shuffles
  for (let t = 0; t < 50; t++) {
    const cand = _.shuffle(stims);
    if (!violatesMaxRun(cand, maxRun)) return cand;
  }

  // Greedy + randomized construction
  let best = null;
  for (let t = 0; t < maxTries; t++) {
    let e = _.shuffle(expPool.slice());
    let n = _.shuffle(nonPool.slice());

    let seq = [];
    let lastCat = null;
    let run = 0;

    while (e.length || n.length) {
      // Which categories are allowed next?
      let allowed = [];
      if (lastCat === "exp" && run >= maxRun) {
        if (n.length) allowed = ["non"]; else allowed = ["exp"];
      } else if (lastCat === "non" && run >= maxRun) {
        if (e.length) allowed = ["exp"]; else allowed = ["non"];
      } else {
        if (e.length) allowed.push("exp");
        if (n.length) allowed.push("non");
      }

      // Weighted pick to avoid starvation
      let pickCat;
      if (allowed.length === 2) {
        const re = e.length, rn = n.length;
        pickCat = (Math.random() < re / (re + rn)) ? "exp" : "non";
      } else {
        pickCat = allowed[0];
      }

      if (pickCat === "exp") {
        const i = Math.floor(Math.random() * e.length);
        seq.push(e.splice(i, 1)[0]);
        if (lastCat === "exp") run += 1; else { lastCat = "exp"; run = 1; }
      } else {
        const i = Math.floor(Math.random() * n.length);
        seq.push(n.splice(i, 1)[0]);
        if (lastCat === "non") run += 1; else { lastCat = "non"; run = 1; }
      }
    }

    if (!violatesMaxRun(seq, maxRun)) return seq;
    // keep best (fewest violations) in case we need a fallback
    if (!best || Math.random() < 0.3) best = seq;
  }

  console.warn("constrainedShuffleStims: fell back to near-best sequence");
  return best || _.shuffle(stims);
}


/// init ///
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
  exp.practice_shuffled = _.shuffle(exp.practice);
  exp.stims_shuffled = constrainedShuffleStims(exp.stims, 2);
  //exp.stims_shuffled = _.shuffle(exp.stims);
    //exp.stims_shuffled = exp.stims; // keep as-is, no shuffle
  exp.randomized_order = exp.stims_shuffled.map(s => s.displayID); // full sequence for the record



  //blocks of the experiment:
  exp.structure=["i0", "instructions", "practice", "afterpractice", "trial", 'subj_info', 'thanks'];

  exp.data_trials = [];
  //make corresponding slides:
  exp.slides = make_slides(exp);

  exp.nQs = utils.get_exp_length(); //this does not work if there are stacks of stims (but does work for an experiment with this structure)
                    //relies on structure and slides being defined

  $('.slide').hide(); //hide everything

  //make sure turkers have accepted HIT (or you're not in mturk)
  $("#start_button").on("click", function () {
  exp.go();
});
;

  exp.go(); //show first slide
}
