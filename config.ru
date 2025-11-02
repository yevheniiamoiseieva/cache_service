# config.ru

# Используем абсолютный путь к текущей директории, который Docker гарантирует
# ENV['RACK_ROOT'] обычно устанавливается в корневую директорию Docker WORKDIR (/app)
require File.expand_path('../app.rb', __FILE__)

run Router