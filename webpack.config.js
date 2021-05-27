const path = require('path');
const { WebpackManifestPlugin } = require('webpack-manifest-plugin');
const webpack = require("webpack");
module.exports = (env, argv) => {
  let mode = argv['mode'];
  return {
    entry: './client/src/index.tsx',
    output: {
      path: path.resolve(__dirname, 'lib', 'inferno', 'public'),
      filename: 'bundle.js',
      publicPath: '/public/',
    },
    devServer: {
      contentBase: '/public/',
      port: 3000
    },
    module: {
      rules: [
        {
          test: /\.tsx?$/,
          use: {
            loader: "babel-loader",
            options: {
              presets: [
                "@babel/preset-env",
                "@babel/preset-react",
                "@babel/preset-typescript",
              ],
            },
          },
          exclude: /node_modules/,
        },
        {
          test: /\.css$/i,
          use: ["style-loader", "css-loader"],
        },
        {
          test: /\.(png|jpe?g|gif)$/i,
          use: [
            {
              loader: 'file-loader',
              options: {
                publicPath: (url, _resourcePath, _context) => {
                  if (mode == 'development') {
                    return `http://localhost:3000/public/${url}`;
                  }
                  else {
                    return `public/${url}`;
                  }
                }
              }
            },
          ],
        },
      ]
    },
    resolve: {
      modules: [path.resolve(__dirname, './client/src'), 'node_modules'],
      extensions: ['.ts', '.tsx', '.js', '.jsx', '.json'],
      alias: {
        components: path.resolve(__dirname, './client/src/components')
      }
    },
    plugins: [
      new WebpackManifestPlugin({
        fileName: path.resolve(__dirname, 'lib', 'inferno', 'public', 'assets.json')
      }),
      new webpack.HotModuleReplacementPlugin()
    ]
  }
}
