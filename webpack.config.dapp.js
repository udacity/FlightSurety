const path = require("path");
const webpack = require('webpack');
const HtmlWebpackPlugin = require("html-webpack-plugin");

module.exports = {
  entry: ['babel-polyfill', path.join(__dirname, "src/dapp")],
  output: {
    path: path.join(__dirname, "prod/dapp"),
    filename: "bundle.js"
  },
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        use: "babel-loader",
        exclude: /node_modules/
      },
      {
        test: /\.css$/,
        use: ["style-loader", "css-loader"]
      },
      {
        test: /\.(png|svg|jpg|gif)$/,
        use: [
          'file-loader'
        ]
      },
      {
        test: /\.html$/,
        use: "html-loader",
        exclude: /node_modules/
      }
    ]
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: path.join(__dirname, "src/dapp/index.html")
    }),
    new webpack.DefinePlugin({
      "process.env": {}
    }),
  ],
  resolve: {
    extensions: [".js"],
    fallback: {
      "assert": false,
      "crypto": false,
      "http": false,
      "https": false,
      "os": false,
      "process": false,
      "stream": false,
      "url": false
    }
  },
  devServer: {
    port: 8000,
    devMiddleware: {
      stats: "minimal"
    },
    static: {
      staticOptions: {
        contentBase: path.join(__dirname, "dapp")
      }
    }
  }
};
