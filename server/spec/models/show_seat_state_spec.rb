require "rails_helper"

RSpec.describe ShowSeatState do
  describe "validations" do
    it "requires lock metadata when status is locked" do
      state = build(
        :show_seat_state,
        status: :locked,
        lock_token: nil,
        locked_until: nil,
        locked_user: nil
      )

      expect(state).not_to be_valid
      expect(state.errors[:lock_token]).to include("can't be blank")
      expect(state.errors[:locked_until]).to include("can't be blank")
      expect(state.errors[:locked_by_user]).to include("can't be blank")
    end

    it "clears lock metadata when status is not locked" do
      state = build(
        :show_seat_state,
        status: :blocked,
        lock_token: "temporary",
        locked_until: 5.minutes.from_now,
        locked_user: create(:user)
      )

      expect(state).to be_valid
      expect(state.lock_token).to be_nil
      expect(state.locked_until).to be_nil
      expect(state.locked_by_user).to be_nil
    end
  end

  describe "#effective_status" do
    it "returns available for expired locks" do
      state = build(
        :show_seat_state,
        status: :locked,
        locked_until: 1.minute.ago
      )

      expect(state.effective_status).to eq("available")
    end

    it "returns original status for active lock and terminal states" do
      locked = build(:show_seat_state, status: :locked, locked_until: 3.minutes.from_now)
      blocked = build(:show_seat_state, :blocked)

      expect(locked.effective_status).to eq("locked")
      expect(blocked.effective_status).to eq("blocked")
    end
  end
end
