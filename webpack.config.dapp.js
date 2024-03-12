const path = require("path");
const webpack = require('webpack');
const HtmlWebpackPlugin = require("html-webpack-plugin");

module.exports = {
  entry: ['core-js/stable', path.join(__dirname, "src/dapp")],
  output: {
    path: path.join(__dirname, "prod/dapp"),
    filename: "bundle.js"
  },
  module: {
    // "http": require.resolve("stream-http"),
    // "crypto": require.resolve("crypto-browserify"),
    // "https": require.resolve("https-browserify"),
    // "os": require.resolve("os-browserify/browser"),
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
    ],
  },
  plugins: [

    new webpack.ProvidePlugin({
      process: 'process/browser',
      Buffer: ['buffer', 'Buffer'],
      http: 'stream-http',
      https: 'https-browserify',
      os: 'os-browserify/browser',
      path: 'path-browserify',
      querystring: 'querystring-es3',
      stream: 'stream-browserify',
      util: 'util'
    }),

    new HtmlWebpackPlugin({ 
      template: path.join(__dirname, "src/dapp/index.html")
    })
  ],
  resolve: {
    extensions: [".js"],
    fallback: {
      "http": require.resolve("stream-http"),
      "https": require.resolve("https-browserify"),
      "os": require.resolve("os-browserify/browser"),
      "stream": false,
      // ...
    }
  },
  devServer: {
    // contentBase: path.join(__dirname, "dapp"),
    static: path.join(__dirname, 'public/'),
  port: 8000,
  hot: "only"
    //stats: "minimal"
  }
};