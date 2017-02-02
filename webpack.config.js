var path = require("path");
var webpack = require("webpack");
var autoprefixer = require('autoprefixer');


var PROD = (process.env.NODE_ENV == "production");

module.exports = {
  devtool: PROD ? "source-map" : "eval",
  entry: {
    'apparatus': ["./src/index"],
    'apparatus-viewer': ["./src/viewer"]
  },
  output: {
    path: path.join(__dirname, "dist"),
    filename: "[name].js",
    publicPath: "/dist/"
  },
  plugins:
    PROD
    ? [
        new webpack.optimize.OccurenceOrderPlugin(),
        new webpack.DefinePlugin({
          "process.env": {
            "NODE_ENV": JSON.stringify("production")
          }
        }),
        new webpack.optimize.UglifyJsPlugin({
          compressor: {
            warnings: false
          }
        })
      ]
    : [
        new webpack.optimize.OccurenceOrderPlugin(),
        new webpack.NoErrorsPlugin()
      ],
  resolve: {
    extensions: ["", ".js", ".coffee"]
  },
  module: {
    loaders: [
      {
        test: /\.coffee$/,
        loader: "coffee-loader"
      },
      {
        test: /\.css$/,
        loader: "style-loader!css-loader"
      },
      {
        test: /\.styl$/,
        loader: "style-loader!css-loader!postcss-loader!stylus-loader"
      }
    ]
  },
  postcss: [
    autoprefixer({browsers: ['last 2 versions']})
  ]
};
