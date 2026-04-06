class HelloWorld
  def self.greet
    "Hello, World!"
  end

  describe "HelloWorld" do
    context "When testing the HelloWorld class" do
      it "returns 'Hello, World!'" do
        expect(HelloWorld.greet).to eq("Hello, World!")
      end
    end
  end
end
