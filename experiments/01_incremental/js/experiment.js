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
    },
    present: exp.practice,
    present_handle : function(stim) {
      
      exp.selection_array=[];
      this.stim = stim; 
      $(".err").hide();
      $(".grid-container").show();

      var instruction = this.stim.instruction1;
      words = instruction.split("|")
      init_instruction = words[0] + " ..."; // The|
      instruction1 = words[0]+ " " + words[1] + " ..."; // The| arrow|
      instruction2 = words[0]+ " " + words[1] + " " + words[2]  + " ...";  // The| arrow| usually lands on| or The| arrow| has a 25% chance of landing on| 
      instruction3 = words[0]+ " " + words[1] + " " + words[2] + " " + words[3];
        
      const instruction_array=[instruction1,instruction2,instruction3]

      $(".sentence").html(init_instruction);
  
      var loc1_img = '<img src="images/'+this.stim.location1+'.png" style="height:150px" class="left">';
      $(".loc1").html(loc1_img);
      var loc2_img = '<img src="images/'+this.stim.location2+'.png" style="height:150px" class="center">';
      $(".loc2").html(loc2_img);
      var loc3_img = '<img src="images/'+this.stim.location3+'.png" style="height:150px" class="center">';
      $(".loc3").html(loc3_img);
      var loc4_img = '<img src="images/'+this.stim.location4+'.png" style="height:150px" class="center">';
      $(".loc4").html(loc4_img);
      var loc5_img = '<img src="images/loc5.png" style="height:50px" class="center">';
      $(".loc5").html(loc5_img);

      $(".loc").bind("click",function(e){
        $(".err").hide();
        e.preventDefault();
        var loc = $(this).data().loc
        if (["AOI5","AOI6"].includes(loc)) {
          $(".err").show();
        }
        else {
          if (exp.counter>2){
            exp.selection_array.push(loc)
            exp.counter = 0;
            $(".loc").unbind('click')
            _s.button();
          } else {
            exp.selection_array.push(loc)
            $(".sentence").html(instruction_array[exp.counter])
            exp.counter++;
          }
        }  
       });
    },

    button : function() {
      console.log("Location array => ",exp.selection_array)
      this.log_responses();
      _stream.apply(this); /* use _stream.apply(this); if and only if there is
      "present" data. (and only *after* responses are logged) */
    },
    
    log_responses : function() {
      exp.data_trials.push({
          "displayID" : this.stim.displayID,
          "ExpFiller" : this.stim.ExpFiller, 
          "location1" : this.stim.location1,
          "location2" : this.stim.location2,
          "location3" : this.stim.location3, 
          "location4" : this.stim.location4, 
          "condition" : this.stim.condition,
          "target" : this.stim.target,
          "competitor" : this.stim.competitor,
          "modal" : this.stim.modal,
          "instruction1" : this.stim.instruction1,
          "correctAns"  : this.stim.correctAns,
          "response" : exp.selection_array, 
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

      var instruction = stim.instruction3;
      words = instruction.split("|")
      init_instruction = words[0] + " ..."; // The
      instruction1 = words[0]+ " " + words[1] + " ..."; // The| arrow|
      instruction2 = words[0]+ " " + words[1] + " " + words[2]  + " ...";  // The| arrow| usually lands on| or The| arrow| has a 25% chance of landing on| 
      instruction3 = words[0]+ " " + words[1] + " " + words[2] + " " + words[3];
        
      const instruction_array=[instruction1,instruction2,instruction3]


      $(".instruction").html(init_instruction);
  
      var loc1_img = '<img src="images/'+stim.location1+'.png"style="height:150px" class="left">';
      $(".loc1").html(loc1_img);
      var loc2_img = '<img src="images/'+stim.location2+'.png" style="height:150px" class="center">';
      $(".loc2").html(loc2_img);
      var loc3_img = '<img src="images/'+stim.location3+'.png" style="height:150px" class="center">';
      $(".loc3").html(loc3_img);
      var loc4_img = '<img src="images/'+stim.location4+'.png" style="height:150px" class="center">';
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
        "displayID" : this.stim.displayID,
        "location1" : this.stim.location1,
        "location2" : this.stim.location2,
        "location3" : this.stim.location3, 
        "location4" : this.stim.location4, 
        "target" : this.stim.target, 
        "competitor" : this.stim.competitor, 
        "condition" : this.stim.condition, 
        "modal" : this.stim.modal, 
        "size" : this.stim.size, 
        "ExpFiller" : this.stim.ExpFiller, 
        "correctAns" : this.stim.correctAns, 
        "list" : this.stim.list, 
        "instruction3" : this.stim.instruction3,
        "response_times" : exp.time_array,
        "response" : exp.selection_array,
    });

    }
  });

  slides.subj_info =  slide({
    name : "subj_info",
    submit : function(e){
      exp.subj_data = {
        language : $("#language").val(),
        enjoyment : $("#enjoyment").val(),
        asses : $('input[name="assess"]:checked').val(),
        age : $("#age").val(),
        gender : $("#gender").val(),
        education : $("#education").val(),
        comments : $("#comments").val(),
        problems: $("#problems").val(),
        fairprice: $("#fairprice").val()
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
          "condition" : exp.condition,
          "subject_information" : exp.subj_data,
          "time_in_minutes" : (Date.now() - exp.startT)/60000
      };
      setTimeout(function() {turk.submit(exp.data);}, 1000);
    }
  });

  return slides;
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

  exp.stims_shuffled = _.shuffle(exp.stims);

  //blocks of the experiment:
  exp.structure=["i0", "instructions", "practice", "afterpractice", "trial", 'subj_info', 'thanks'];
  //exp.structure=["i0", "instructions", "trial", 'subj_info', 'thanks'];

  exp.data_trials = [];
  //make corresponding slides:
  exp.slides = make_slides(exp);

  exp.nQs = utils.get_exp_length(); //this does not work if there are stacks of stims (but does work for an experiment with this structure)
                    //relies on structure and slides being defined

  $('.slide').hide(); //hide everything

  //make sure turkers have accepted HIT (or you're not in mturk)
  $("#start_button").click(function() {
    if (turk.previewMode) {
      $("#mustaccept").show();
    } else {
      $("#start_button").click(function() {$("#mustaccept").show();});
      exp.go();
    }
  });

  exp.go(); //show first slide
}
