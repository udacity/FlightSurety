const webpack = require('webpack')
const path = require('path')
const nodeExternals = require('webpack-node-externals')
const StartServerPlugin = require('start-server-webpack-plugin')

module.exports = {
    // entry: 
    // {
        // server: [
        //   'webpack/hot/poll?1000',
        //   './src/server/index'
        // ['./src/server/server.js']
        // ]
    //   },
    // [
    //     'webpack/hot/poll?1000',
    //     './src/server/index'
    // ],
    entry: './src/server/server.js',
    watch: true,
    target: 'node',
    externals: [
        nodeExternals({
          allowlist: [/^webpack\/hot\/poll\?100/], // Update this line
        }),
      ],
    module: {
        rules: [{
            test: /\.js?$/,
            use: 'babel-loader',
            exclude: /node_modules/
        }]
    },
    plugins: [
        // new StartServerPlugin({name: 'server.js',
        // nodeArgs: ['--inspect=0.0.0.0:9229'],
        // signal: false, // signal to use for HMR (defaults to `false`)
        // keyboard: true, // Allow typing 'rs' to restart the server. default: `false`
        // }),
        new webpack.HotModuleReplacementPlugin(),
        new webpack.NoEmitOnErrorsPlugin(),
        new webpack.DefinePlugin({
            "process.env": {
                "BUILD_TARGET": JSON.stringify('server')
            }
        }),
    ],
    optimization: {
        moduleIds: 'named'
     },
    output: {
        path: path.join(__dirname, 'prod/server'),
        filename: 'server.js'
    }
}