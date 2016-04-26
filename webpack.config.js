var path = require("path");
var webpack = require("webpack");
var ExtractTextPlugin = require("extract-text-webpack-plugin");
var autoprefixer = require('autoprefixer');


var PROD = (process.env.NODE_ENV == "production");

stylePlugin = new ExtractTextPlugin("apparatus.css", {
  allChunks: true
})

module.exports = {
  devtool: PROD ? "source-map" : "eval",
  entry: ["./src/index", "./style/index.styl"],
  output: {
    path: path.join(__dirname, "dist"),
    filename: "apparatus.js",
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
        }),
        stylePlugin
      ]
    : [
        new webpack.optimize.OccurenceOrderPlugin(),
        new webpack.NoErrorsPlugin(),
        stylePlugin
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
        test: /\.styl$/,
        loader: ExtractTextPlugin.extract("style-loader", "css-loader!postcss-loader!stylus-loader")
      }
    ]
  },
  postcss: [
    autoprefixer({browsers: ['last 2 versions']})
  ]
};
