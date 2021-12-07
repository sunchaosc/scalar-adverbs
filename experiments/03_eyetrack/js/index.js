function make_slides(f) {
  var slides = {};

  // slides.i0 = slide({
  //   name : "i0",
  //   start: function() {
  //   exp.startT = Date.now();
  //   }
  // });

  slides.i0 = slide({
    name: "i0",
    exp_start: function () {
      $("#img_instructions").hide();
      $("#scene_instructions").hide();
      $("#sound_test_err").hide();
      // exp.startT = Date.now();
    }
  });

  slides.startPage = slide({
    name: "startPage",
    exp_start: function () { },
    start: function () {
    },
    button: function () {
      exp.go()
    }
  });

  slides.training_and_calibration = slide({
    name: "training_and_calibration",
    start_camera: function (e) {
      $("#start_camera").hide();
      $("#start_calibration").show();
      init_webgazer();
    },
    finish_calibration_start_task: function (e) {
      if (precision_measurement >= PRECISION_CUTOFF) {
        // hide webgazer video feed and prediction points
        hideVideoElements();

        webgazer.pause();
        exp.trial_no = 0;
        exp.go();
      }
      else {
        exp.accuracy_attempts.push(precision_measurement);
        swal({
          title: "Calibration Fail",
          text: "Either you haven't performed the calibration yet, or your calibration score is too low. \
           Your calibration score must be 50% to begin the task. Please click Calibrate to try calibrating again. \
           Click Instructions to see tips for calibrating.",
          buttons: {
            cancel: false,
            confirm: true
          }
        })
      }
    }
  });

  slides.instructions = slide({
    name : "instructions",
    button : function() {
      exp.go(); //use exp.go() if and only if there is no "present" data.
    }
  });


  slides.sound_test = slide({
    name: "sound_test",
    soundtest_OK: function (e) {
      exp.trial_no = 0;
      exp.go();
    }
  });


  slides.practice = slide({
    name : "practice",
    start: function(){
      // exp.counter = 0;
      $(".err").hide();
    //  $(".correct").hide();
    },
    present: exp.practice,
    present_handle : function(stim) {
      exp.playing = false;
      this.stim = stim;

      exp.selection;
      exp.rt = 0;
      exp.trial_start = Date.now();
      // display images
      $(".loc1").attr('src', "images/" + this.stim.location1 + '.png');
      $(".loc2").attr('src', "images/" + this.stim.location2 + '.png');
      $(".loc3").attr('src', "images/" + this.stim.location3 + '.png');
      $(".loc4").attr('src', "images/" + this.stim.location4 + '.png');
      $(".loc5").attr('src', "images/" + this.stim.location5 + '.png');
      $(".imgwrapper").show();

      exp.prime = this.stim.prime
      setTimeout(function () {
        aud = document.getElementById("stim");
        aud.src = "audio/" + exp.prime + ".wav";
        aud.currentTime = 0;
        aud.play();
        // console.log("Play audio")
        exp.audio_play_unix = Date.now();
        exp.playing = true;
        // when audio ends
        aud.addEventListener('ended', function () {
          exp.playing = false;
        }, false);
        // make images clickable
        $('img').bind("click", function (e) {
          e.preventDefault();
            if (exp.playing == false) {
              exp.selection = $(this).attr("id")
              exp.rt = (Date.now() - exp.trial_start);
              $('img').unbind('click')
              _s.button();
            }
        });
      }, 1);
    },

    button : function() {
      this.log_responses();
      _stream.apply(this); /* use _stream.apply(this); if and only if there is
      "present" data. (and only *after* responses are logged) */
    },

    log_responses: function () {
      exp.data_trials.push({
        "slide_number": exp.phase,
        "displayID": this.stim.displayID,
        "trial_type": this.stim.ExpFiller,
        "audio": this.stim.Prime,
        "list": this.stim.list,
        "location1": this.stim.location1,
        "location2": this.stim.location2,
        "location3": this.stim.location3,
        "location4": this.stim.location4,

        "target" : this.stim.target,
        "competitor" : this.stim.competitor,
        "condition" : this.stim.condition,
        "modal" : this.stim.modal,
        "correctAns" : this.stim.correctAns,
        "instruction3" : this.stim.instruction3,
        //"response_times" : exp.time_array,
        //"response" : exp.selection_array,

        "response": exp.selection,
        "response_time": exp.rt
      });
    }
  });

      // var loc1_img = '<img src="images/'+this.stim.location1+'.png" style="height:150px" class="left">';
      // $(".loc1").html(loc1_img);
      // var loc2_img = '<img src="images/'+this.stim.location2+'.png" style="height:150px" class="center">';
      // $(".loc2").html(loc2_img);
      // var loc3_img = '<img src="images/'+this.stim.location3+'.png" style="height:150px" class="center">';
      // $(".loc3").html(loc3_img);
      // var loc4_img = '<img src="images/'+this.stim.location4+'.png" style="height:150px" class="center">';
      // $(".loc4").html(loc4_img);
      // var loc5_img = '<img src="images/loc5.png" style="height:50px" class="center">';
      // $(".loc5").html(loc5_img);

      // $(".loc").bind("click",function(e){
      //   $(".err").hide();
      //   $(".correct").hide();
      //   e.preventDefault();
      //   var loc = $(this).data().loc
      //
      //     if (exp.counter==3){
      //       if (loc === correctAns) {
      //       $(".correct").show();
      //       exp.counter++;
      //       }
      //       else {
      //       $(".err").show();
      //       exp.counter++;
      //       }
      //     }
      //     else if (exp.counter>3){
      //       exp.selection_array.push(loc)
      //       exp.counter = 0;
      //       $(".loc").unbind('click')
      //       _s.button();
      //     }
      //    else {
      //       exp.selection_array.push(loc)
      //       $(".sentence").html(instruction_array[exp.counter])
      //       exp.counter++;
      //       }
      //    }
      //  );


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
      //exp.counter = 0;

    },
    present_handle : function(stim) {
      $(".cross_center").hide();
      exp.selection;
      exp.rt = 0;
      exp.unix_rt = 0;
      exp.trial_start = Date.now();
      exp.playing = false;

      //exp.selection_array=[];
      //exp.time_array=[];
      //console.log("time:"+(Date.now()-exp.trial_start))

      $(".err").hide();
      //$(".grid-container").show();

      this.stim = stim; // store this information in the slide so you can record it later
      $(".loc1").attr('src', "images/" + stim.location1 + '.png');
      $(".loc2").attr('src', "images/" + stim.location2 + '.png');
      $(".loc3").attr('src', "images/" + stim.location3 + '.png');
      $(".loc4").attr('src', "images/" + stim.location4 + '.png');
      $(".loc5").attr('src', "images/" + stim.location5 + '.png');
      $(".imgwrapper").show();

      if (!exp.DUMMY_MODE) {
        hideVideoElements();
        startGazer();
        hideVideoElements();
        //console.log("started gazer")
        webgazer.setGazeListener(function (data, elapsedTime) {
          if (data == null) {
            return;
          }
          var xprediction = data.x;
          var yprediction = data.y;
          var unixtime = Date.now(); // unix timestamp - so you have absolute timestamps
          exp.tlist.push(elapsedTime); // this is the elapsed time since webgazer initialized
          exp.unixtlist.push(unixtime);
          exp.xlist.push(xprediction);
          exp.ylist.push(yprediction);
        });
      }

      setTimeout(function () {
        aud = document.getElementById("stim");
        aud.src = "audio/" + exp.prime + ".wav";
        aud.currentTime = 0;
        aud.play();
        // console.log("Play audio")
        exp.audio_play_unix = Date.now();
        exp.playing = true;
        // when audio ends
        aud.addEventListener('ended', function () {
          exp.playing = false;
        }, false);
        // make images clickable
        $('img').bind("click", function (e) {
          e.preventDefault();
            if (exp.playing == false) {
              exp.selection = $(this).attr("id")
              console.log("selection", exp.selection)
              exp.rt = (Date.now() - exp.trial_start);
              $('img').unbind('click')
              _s.button();
            }
        });

      }, 1);
    },

    button: function () {
      webgazer.pause();
      exp.rt = exp.unix_rt - exp.trial_start;
      // console.log("Trial start: ", exp.trial_start)
      // console.log("Selection: ", exp.selection);
      // console.log("RT: ", exp.rt);
      // console.log("Unix RT: ", exp.unix_rt);
      // console.log("Audio play unix: ", exp.audio_play_unix)
      this.log_responses();
      exp.tlist = [];
      exp.unixtlist = [];
      exp.xlist = [];
      exp.ylist = [];

      // fixation cross
      exp.this = this
      $(".imgwrapper").hide();
      $(".cross_center").show();
      setTimeout(function () {
        _stream.apply(exp.this);
      }, 1000);
    },

    log_responses: function () {
      exp.data_trials.push({
        "slide_number": exp.phase,
        "displayID": this.stim.displayID,
        "trial_type": this.stim.ExpFiller,
        "audio": this.stim.Prime,
        "list": this.stim.list,
        "location1": this.stim.location1,
        "location2": this.stim.location2,
        "location3": this.stim.location3,
        "location4": this.stim.location4,

        "target" : this.stim.target,
        "competitor" : this.stim.competitor,
        "condition" : this.stim.condition,
        "modal" : this.stim.modal,
        "correctAns" : this.stim.correctAns,
        "instruction3" : this.stim.instruction3,
        //"response_times" : exp.time_array,
        //"response" : exp.selection_array,

        "response": exp.selection,
        "response_time": exp.rt,
        "trial_start" : exp.trial_start,
        "unix_rt": exp.unix_rt,
        "audio_play_unix": exp.audio_play_unix,
        "webgazer_time": exp.tlist,
        "unixtlist" : exp.unixtlist,
        'x': exp.xlist,
        'y': exp.ylist
      });
    }
  });

  slides.subj_info =  slide({
    name : "subj_info",
    submit : function(e){

      headphones = $("#headphones").val();
      eyesight = $("#eyesight").val();
      eyesight_task = $("#eyesight_task").val();

      // camblock = $("#camblock").val();
      // if (lg == '' || age == '' || gender == '' || headphones == '' || eyesight == '-1' || eyesight_task == '-1' || payfair == '-1' || camblock == '-1') {
      //   $(".err_part2").show();
      // } else {
      //   $(".err_part2").hide();
      exp.subj_data = {
        prolificID: $("#ProlificID").val(),
        gender : $("#gender").val(),
        age : $("#age").val(),
        language : $("#language").val(),
        headphones: headphones,
        eyesight: eyesight,
        eyesight_task: eyesight_task,
        comments : $("#comments").val(),
        accuracy: precision_measurement,
        previous_accuracy_attempts: exp.accuracy_attempts,
        time_in_minutes: (Date.now() - exp.startT) / 60000
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
      proliferate.submit(exp.data);
    }
  });

  return slides;
}

/// init ///
function init() {
  // exp.trials = [];
  // exp.catch_trials = [];

  function preload() {
    for (pos in exp.stims) {
      new Audio().src = "audio/" + exp.stims[pos].Prime + ".wav";
    };
    console.log("loaded all the audio");
    for (pos in exp.stims) {
      for (var i = 1; i <= 10; i++) {
        var locnum = "location" + i;
        new Image().src = "images/" + exp.stims[pos][locnum] + ".png";
      };
    };
    console.log("loaded all the images");
  };
  preload();

  //Experiment constants
  exp.DUMMY_MODE = true; // set to true if want to test without eyetracking
  exp.N_TRIALS = 36
  PRECISION_CUTOFF = 50;
  IMG_HEIGHT = 150   // size of imgs - just for your records -- TODO: change
  IMG_WIDTH = 150

  exp.system = {
      Browser : BrowserDetect.browser,
      OS : BrowserDetect.OS,
      screenH: screen.height,
      screenW: screen.width,
      windowH: window.innerHeight,
      windowW: window.innerWidth,
      imageH: IMG_HEIGHT,
      imageW: IMG_WIDTH
      // screenUH: exp.height,
      // screenW: screen.width,
      // screenUW: exp.width
    };

    // min size the browser needs to be for current setup
    exp.minWindowWidth = 1280
    exp.minWindowHeight = 750

    //Initializing data frames
    exp.tlist = [];
    exp.unixtlist = [];
    exp.xlist = [];
    exp.ylist = [];
    exp.clicked = null
    exp.accuracy_attempts = []

  exp.stims_shuffled = _.shuffle(exp.stims);

  //blocks of the experiment:
  // exp.structure=["i0", "instructions", "practice", "afterpractice", "trial", 'subj_info', 'thanks'];
  //exp.structure=["i0", "instructions", "trial", 'subj_info', 'thanks'];

  if (!exp.DUMMY_MODE) {
    exp.structure = ["i0", "training_and_calibration", "startPage", "instructions", "sound_test", "practice", "afterpractice", "trial", 'subj_info', 'thanks'];
  } else {
    exp.structure = ["i0", "startPage", "instructions", "sound_test", "practice", "afterpractice", "trial", 'subj_info', 'thanks'];
  }

  exp.data_trials = [];
  //make corresponding slides:
  exp.slides = make_slides(exp);

  exp.nQs = utils.get_exp_length(); //this does not work if there are stacks of stims (but does work for an experiment with this structure)
                    //relies on structure and slides being defined

  $('.slide').hide(); //hide everything

  $("#windowsize_err").hide();
  $("#sound_test_err").hide();

  //make sure turkers have accepted HIT (or you're not in mturk)
  $("#start_button").click(function () {
    if (turk.previewMode) {
      $("#mustaccept").show();
    } else {
      $("#start_button").click(function () { $("#mustaccept").show(); });
      if (window.innerWidth >= exp.minWindowWidth & window.innerHeight >= exp.minWindowHeight) {
        exp.startT = Date.now();
        exp.go();
        if (!exp.DUMMY_MODE) {
          ClearCanvas();
          helpModalShow();
          $("#start_calibration").hide();
          $("#begin_task").hide();
        }
      }
      else {
        $("#windowsize_err").show();
      }
    }
  });

  $(".response_button").click(function () {
    var val = $(this).val();
    _s.continue_button(val);
  });

  exp.go(); //show first slide
}


    //   exp.prime = this.stim.Prime
    //
    //   var instruction = stim.instruction3;
    //   words = instruction.split("|")
    //   init_instruction = words[0] + " ..."; // In the |
    //   instruction1 = words[0]+ " " + words[1] + " ..."; // In the |basket, |
    //   instruction2 = words[0]+ " " + words[1] + " " + words[2]  + " ...";  // In the |basket, | some of the flowers are \
    //   instruction3 = words[0]+ " " + words[1] + " " + words[2] + " " + words[3];// In the |basket, | some of the flowers are \pink.
    //
    //   const instruction_array=[instruction1,instruction2,instruction3]
    //
    //
    //   $(".instruction").html(init_instruction);
    //
    //   var loc1_img = '<img src="images/'+stim.location1+'.png"style="height:150px" class="left">';
    //   $(".loc1").html(loc1_img);
    //   var loc2_img = '<img src="images/'+stim.location2+'.png" style="height:150px" class="center">';
    //   $(".loc2").html(loc2_img);
    //   var loc3_img = '<img src="images/'+stim.location3+'.png" style="height:150px" class="center">';
    //   $(".loc3").html(loc3_img);
    //   var loc4_img = '<img src="images/'+stim.location4+'.png" style="height:150px" class="center">';
    //   $(".loc4").html(loc4_img);
    //   var loc5_img = '<img src="images/loc5.png" style="height:50px" class="center">';
    //   $(".loc5").html(loc5_img);
    //
    //
    //   $(".loc").bind("click",function(e){
    //     e.preventDefault();
    //     if (exp.counter>2){
    //       exp.selection_array.push($(this).data().loc)
    //       exp.time_array.push(Date.now()-exp.trial_start)
    //       console.log("time:" + (Date.now()-exp.trial_start))
    //       exp.counter = 0;
    //       $(".loc").unbind('click')
    //       _s.button();
    //     } else {
    //       exp.selection_array.push($(this).data().loc)
    //       exp.time_array.push(Date.now()-exp.trial_start)
    //       console.log("time:" + (Date.now()-exp.trial_start))
    //       $(".instruction").html(instruction_array[exp.counter])
    //       exp.counter++;
    //     }
    //    });
    //
    // },
