const path = require('path');

module.exports = {
  mode: process.env.NODE_ENV === 'production' ? 'production' : 'development',
  entry: path.resolve(__dirname, "src/main"),
  output: {
    path: path.resolve(__dirname, "dist"),
    filename: "bundle.js",
    publicPath: '/hw01-fireball-base/',
  },
  module: {
    rules: [
      {
        test: /\.ts$/,
        use: 'ts-loader',
        exclude: /node_modules/
      },
      {
        test: /\.glsl$/,
        loader: 'webpack-glsl-loader'
      },
      {
        test: /\.mp3$/,
        loader: 'file-loader',
      },
    ]
  },
  resolve: {
    extensions: ['.ts', '.js' ],
  },
  devtool: 'source-map',
  devServer: {
    port: 7000,
    static: {
      directory: path.join(__dirname, 'dist'),
    },
    client: {
      overlay: true,
    }
  },
};
