/* index.js — drop-in build
   - Practice: pure shuffle
   - Main trials: pure shuffle (same rule as practice)
   - Keeps your slide flow and logging (presentation_index, randomized_order)
*/

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
        "instruction1": this.stim.instruction1,
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

  // Main trials: pure uniform shuffle (same as practice)
  exp.stims_shuffled = _.shuffle(exp.stims);

  // Store full order for record (by displayID if available)
  exp.randomized_order = exp.stims_shuffled.map(s => s.displayID || s.item_id || "NA");

  // blocks of the experiment:
  exp.structure = ["i0", "instructions", "practice", "afterpractice", "trial", "subj_info", "thanks"];

  exp.data_trials = [];
  // make corresponding slides:
  exp.slides = make_slides(exp);

  exp.nQs = utils.get_exp_length();

  $('.slide').hide();

  $("#start_button").on("click", function () { exp.go(); });
  exp.go(); // show first slide
}
