cask "avro-keyboard" do
  version "1.0.0"
  sha256 :no_check

  url "https://github.com/rashomon-gh/iAvro-Swift/releases/download/#{version}/Avro-Keyboard-#{version}.zip"
  name "Avro Keyboard"
  desc "Bengali phonetic input method for macOS using Avro Phonetic"
  homepage "https://github.com/rashomon-gh/iAvro-Swift"

  depends_on macos: ">= :sequoia"

  input_method "Avro-Keyboard-Release/Avro Keyboard.app"

  caveats do
    <<~EOS
      After installing, add Avro Keyboard from:
        System Settings → Keyboard → Input Sources → Edit → +
    EOS
  end

  uninstall delete: "~/Library/Input Methods/Avro Keyboard.app"

  zap delete: [
    "~/Library/Application Support/OmicronLab",
  ]
end
