package body Editor.Buffer_Switcher.Review_Operations is

   use type Editor.Buffer_Switcher.Switcher_Review_Mode;

   procedure Set_Switcher_Review_Mode
     (State : in out Buffer_Switcher_State;
      Mode  : Switcher_Review_Mode)
   is
   begin
      State.Active_Review := Mode;
   end Set_Switcher_Review_Mode;

   procedure Clear_Switcher_Review_Mode
     (State : in out Buffer_Switcher_State;
      Mode  : Switcher_Review_Mode)
   is
   begin
      if State.Active_Review = Mode then
         State.Active_Review := No_Review;
      end if;
   end Clear_Switcher_Review_Mode;

   procedure Toggle_Switcher_Review_Mode
     (State : in out Buffer_Switcher_State;
      Mode  : Switcher_Review_Mode)
   is
   begin
      if State.Active_Review = Mode then
         State.Active_Review := No_Review;
      else
         State.Active_Review := Mode;
      end if;
   end Toggle_Switcher_Review_Mode;

   function Has_Switcher_Review_Mode
     (State : Buffer_Switcher_State;
      Mode  : Switcher_Review_Mode) return Boolean
   is
   begin
      return State.Active_Review = Mode;
   end Has_Switcher_Review_Mode;

   procedure Clear_Dirty_Prune_Apply_Review_Modes
     (State : in out Buffer_Switcher_State)
   is
   begin
      if State.Active_Review = Dirty_Prune_Apply_Review
        or else State.Active_Review = Removed_Dirty_Prune_Apply_Review
      then
         State.Active_Review := No_Review;
      end if;
   end Clear_Dirty_Prune_Apply_Review_Modes;

   procedure Clear_Dirty_Prune_Preview_Review_Modes
     (State : in out Buffer_Switcher_State)
   is
   begin
      if State.Active_Review = Dirty_Prune_Preview_Review
        or else State.Active_Review = Removed_Dirty_Prune_Preview_Review
      then
         State.Active_Review := No_Review;
      end if;
   end Clear_Dirty_Prune_Preview_Review_Modes;

   procedure Clear_Pending_Marked_Review_Modes
     (State : in out Buffer_Switcher_State)
   is
   begin
      case State.Active_Review is
         when Pending_Marked_Close_Review
            | Pruned_Pending_Close_Review
            | Dirty_Pending_Close_Review
            | Dirty_Prune_Preview_Review
            | Removed_Dirty_Prune_Preview_Review
            | Dirty_Prune_Apply_Review
            | Removed_Dirty_Prune_Apply_Review =>
            State.Active_Review := No_Review;
         when No_Review | Marked_Review =>
            null;
      end case;
   end Clear_Pending_Marked_Review_Modes;

   procedure Show_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Set_Switcher_Review_Mode (State, Marked_Review);
   end Show_Marked_Review;

   procedure Hide_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Clear_Switcher_Review_Mode (State, Marked_Review);
   end Hide_Marked_Review;

   procedure Toggle_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Toggle_Switcher_Review_Mode (State, Marked_Review);
   end Toggle_Marked_Review;

   function Has_Marked_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Has_Switcher_Review_Mode (State, Marked_Review);
   end Has_Marked_Review;

   function Marked_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      if Has_Marked_Review (State) then
         return "marked";
      else
         return "off";
      end if;
   end Marked_Review_Description;

   procedure Show_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      if State.Pending_Action /= No_Pending_Marked_Action
        and then Natural (State.Pending_Targets.Length) > 0
      then
         Set_Switcher_Review_Mode (State, Pending_Marked_Close_Review);
      end if;
   end Show_Pending_Marked_Review;

   procedure Hide_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Clear_Switcher_Review_Mode (State, Pending_Marked_Close_Review);
   end Hide_Pending_Marked_Review;

   procedure Toggle_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      if Has_Pending_Marked_Review (State) then
         Hide_Pending_Marked_Review (State);
      else
         Show_Pending_Marked_Review (State);
      end if;
   end Toggle_Pending_Marked_Review;

   function Has_Pending_Marked_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Has_Switcher_Review_Mode (State, Pending_Marked_Close_Review);
   end Has_Pending_Marked_Review;

   function Pending_Marked_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      if Has_Pending_Marked_Review (State) then
         return "pending close";
      else
         return "off";
      end if;
   end Pending_Marked_Review_Description;

   procedure Show_Pruned_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      if State.Pending_Action = Pending_Marked_Close
        and then Natural (State.Pruned_Pending_Targets.Length) > 0
      then
         Set_Switcher_Review_Mode (State, Pruned_Pending_Close_Review);
      end if;
   end Show_Pruned_Pending_Marked_Review;

   procedure Hide_Pruned_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Clear_Switcher_Review_Mode (State, Pruned_Pending_Close_Review);
   end Hide_Pruned_Pending_Marked_Review;

   procedure Toggle_Pruned_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      if Has_Pruned_Pending_Marked_Review (State) then
         Hide_Pruned_Pending_Marked_Review (State);
      else
         Show_Pruned_Pending_Marked_Review (State);
      end if;
   end Toggle_Pruned_Pending_Marked_Review;

   function Has_Pruned_Pending_Marked_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Has_Switcher_Review_Mode (State, Pruned_Pending_Close_Review);
   end Has_Pruned_Pending_Marked_Review;

   function Pruned_Pending_Marked_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      if Has_Pruned_Pending_Marked_Review (State) then
         return "pruned pending close";
      else
         return "off";
      end if;
   end Pruned_Pending_Marked_Review_Description;

   procedure Show_Dirty_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      if State.Pending_Action = Pending_Marked_Close then
         Set_Switcher_Review_Mode (State, Dirty_Pending_Close_Review);
      end if;
   end Show_Dirty_Pending_Marked_Review;

   procedure Hide_Dirty_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      Clear_Switcher_Review_Mode (State, Dirty_Pending_Close_Review);
   end Hide_Dirty_Pending_Marked_Review;

   procedure Toggle_Dirty_Pending_Marked_Review (State : in out Buffer_Switcher_State) is
   begin
      if Has_Dirty_Pending_Marked_Review (State) then
         Hide_Dirty_Pending_Marked_Review (State);
      else
         Show_Dirty_Pending_Marked_Review (State);
      end if;
   end Toggle_Dirty_Pending_Marked_Review;

   function Has_Dirty_Pending_Marked_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Has_Switcher_Review_Mode (State, Dirty_Pending_Close_Review);
   end Has_Dirty_Pending_Marked_Review;

   function Dirty_Pending_Marked_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      if Has_Dirty_Pending_Marked_Review (State) then
         return "dirty pending close";
      else
         return "off";
      end if;
   end Dirty_Pending_Marked_Review_Description;

   procedure Show_Dirty_Prune_Review (State : in out Buffer_Switcher_State) is
   begin
      if Natural (State.Dirty_Prune_Targets.Length) > 0 then
         Set_Switcher_Review_Mode (State, Dirty_Prune_Preview_Review);
      end if;
   end Show_Dirty_Prune_Review;

   procedure Hide_Dirty_Prune_Review (State : in out Buffer_Switcher_State) is
   begin
      Clear_Switcher_Review_Mode (State, Dirty_Prune_Preview_Review);
   end Hide_Dirty_Prune_Review;

   procedure Toggle_Dirty_Prune_Review (State : in out Buffer_Switcher_State) is
   begin
      if Has_Dirty_Prune_Review (State) then
         Hide_Dirty_Prune_Review (State);
      else
         Show_Dirty_Prune_Review (State);
      end if;
   end Toggle_Dirty_Prune_Review;

   function Has_Dirty_Prune_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Has_Switcher_Review_Mode (State, Dirty_Prune_Preview_Review);
   end Has_Dirty_Prune_Review;

   function Dirty_Prune_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      if Has_Dirty_Prune_Review (State) then
         return "dirty prune preview";
      else
         return "off";
      end if;
   end Dirty_Prune_Review_Description;

   procedure Show_Removed_Dirty_Prune_Review (State : in out Buffer_Switcher_State) is
   begin
      if Natural (State.Removed_Dirty_Prune_Targets.Length) > 0 then
         Set_Switcher_Review_Mode (State, Removed_Dirty_Prune_Preview_Review);
      end if;
   end Show_Removed_Dirty_Prune_Review;

   procedure Hide_Removed_Dirty_Prune_Review (State : in out Buffer_Switcher_State) is
   begin
      Clear_Switcher_Review_Mode (State, Removed_Dirty_Prune_Preview_Review);
   end Hide_Removed_Dirty_Prune_Review;

   procedure Toggle_Removed_Dirty_Prune_Review (State : in out Buffer_Switcher_State) is
   begin
      if Has_Removed_Dirty_Prune_Review (State) then
         Hide_Removed_Dirty_Prune_Review (State);
      else
         Show_Removed_Dirty_Prune_Review (State);
      end if;
   end Toggle_Removed_Dirty_Prune_Review;

   function Has_Removed_Dirty_Prune_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Has_Switcher_Review_Mode (State, Removed_Dirty_Prune_Preview_Review);
   end Has_Removed_Dirty_Prune_Review;

   function Removed_Dirty_Prune_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      if Has_Removed_Dirty_Prune_Review (State) then
         return "removed dirty-prune targets";
      else
         return "off";
      end if;
   end Removed_Dirty_Prune_Review_Description;

   procedure Show_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State) is
   begin
      if Natural (State.Dirty_Prune_Apply_Targets.Length) > 0 then
         Set_Switcher_Review_Mode (State, Dirty_Prune_Apply_Review);
      end if;
   end Show_Dirty_Prune_Apply_Review;

   procedure Hide_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State) is
   begin
      Clear_Switcher_Review_Mode (State, Dirty_Prune_Apply_Review);
   end Hide_Dirty_Prune_Apply_Review;

   procedure Toggle_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State) is
   begin
      if Has_Dirty_Prune_Apply_Review (State) then
         Hide_Dirty_Prune_Apply_Review (State);
      else
         Show_Dirty_Prune_Apply_Review (State);
      end if;
   end Toggle_Dirty_Prune_Apply_Review;

   function Has_Dirty_Prune_Apply_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Has_Switcher_Review_Mode (State, Dirty_Prune_Apply_Review);
   end Has_Dirty_Prune_Apply_Review;

   function Dirty_Prune_Apply_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      if Has_Dirty_Prune_Apply_Review (State) then
         return "dirty-prune apply";
      else
         return "off";
      end if;
   end Dirty_Prune_Apply_Review_Description;

   procedure Show_Removed_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State) is
   begin
      if Natural (State.Removed_Dirty_Prune_Apply_Targets.Length) > 0 then
         Set_Switcher_Review_Mode (State, Removed_Dirty_Prune_Apply_Review);
      end if;
   end Show_Removed_Dirty_Prune_Apply_Review;

   procedure Hide_Removed_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State) is
   begin
      Clear_Switcher_Review_Mode (State, Removed_Dirty_Prune_Apply_Review);
   end Hide_Removed_Dirty_Prune_Apply_Review;

   procedure Toggle_Removed_Dirty_Prune_Apply_Review (State : in out Buffer_Switcher_State) is
   begin
      if Has_Removed_Dirty_Prune_Apply_Review (State) then
         Hide_Removed_Dirty_Prune_Apply_Review (State);
      else
         Show_Removed_Dirty_Prune_Apply_Review (State);
      end if;
   end Toggle_Removed_Dirty_Prune_Apply_Review;

   function Has_Removed_Dirty_Prune_Apply_Review (State : Buffer_Switcher_State) return Boolean is
   begin
      return Has_Switcher_Review_Mode (State, Removed_Dirty_Prune_Apply_Review);
   end Has_Removed_Dirty_Prune_Apply_Review;

   function Removed_Dirty_Prune_Apply_Review_Description (State : Buffer_Switcher_State) return String is
   begin
      if Has_Removed_Dirty_Prune_Apply_Review (State) then
         return "removed dirty-prune apply targets";
      else
         return "off";
      end if;
   end Removed_Dirty_Prune_Apply_Review_Description;

end Editor.Buffer_Switcher.Review_Operations;
