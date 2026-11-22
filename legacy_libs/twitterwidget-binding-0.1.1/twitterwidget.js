HTMLWidgets.widget({

  name: 'twitterwidget',

  type: 'output',

  factory: function(el, width, height) {

    return {

      renderValue: function(x) {

          twttr.widgets.createTweet(
            x.twid,
            document.getElementById(el.id),
            x.pars
          );

      },

      resize: function(width, height) {

        // TODO: currently ignoring resize.

      }

    };
  }
});
