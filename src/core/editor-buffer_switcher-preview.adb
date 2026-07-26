with Editor.Buffers;

package body Editor.Buffer_Switcher.Preview is

   procedure Show_Preview
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) is
   begin
      State.Preview_Visible := True;
   end Show_Preview;

   procedure Hide_Preview
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) is
   begin
      State.Preview_Visible := False;
      State.Preview_Target_Id := Editor.Buffers.No_Buffer;
      State.Preview_Anchor := 1;
      State.Preview_Scroll := 0;
   end Hide_Preview;

   procedure Toggle_Preview
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) is
   begin
      if State.Preview_Visible then
         Hide_Preview (State);
      else
         Show_Preview (State);
      end if;
   end Toggle_Preview;

   function Has_Preview
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean is
   begin
      return State.Preview_Visible;
   end Has_Preview;

   procedure Set_Preview_Target
     (State       : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Target      : Editor.Buffer_Types.Buffer_Id;
      Anchor_Line : Natural)
   is
   begin
      if Target = Editor.Buffers.No_Buffer then
         Clear_Preview_Target (State);
      else
         State.Preview_Target_Id := Target;
         State.Preview_Anchor := Natural'Max (1, Anchor_Line);
         State.Preview_Scroll := 0;
      end if;
   end Set_Preview_Target;

   procedure Clear_Preview_Target
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) is
   begin
      State.Preview_Target_Id := Editor.Buffers.No_Buffer;
      State.Preview_Anchor := 1;
      State.Preview_Scroll := 0;
   end Clear_Preview_Target;

   function Preview_Target
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State)
      return Editor.Buffer_Types.Buffer_Id is
   begin
      return State.Preview_Target_Id;
   end Preview_Target;

   function Preview_Anchor_Line
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Natural is
   begin
      return State.Preview_Anchor;
   end Preview_Anchor_Line;

   function Preview_Scroll_Offset
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Natural is
   begin
      return State.Preview_Scroll;
   end Preview_Scroll_Offset;

   procedure Scroll_Preview_Next_Line
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) is
   begin
      if State.Preview_Visible and then State.Preview_Target_Id /= Editor.Buffers.No_Buffer then
         State.Preview_Scroll := State.Preview_Scroll + 1;
      end if;
   end Scroll_Preview_Next_Line;

   procedure Scroll_Preview_Previous_Line
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) is
   begin
      if State.Preview_Visible and then State.Preview_Target_Id /= Editor.Buffers.No_Buffer then
         if State.Preview_Scroll > 0 then
            State.Preview_Scroll := State.Preview_Scroll - 1;
         elsif State.Preview_Anchor > 1 then
            State.Preview_Anchor := State.Preview_Anchor - 1;
         end if;
      end if;
   end Scroll_Preview_Previous_Line;

   procedure Center_Preview_On_Line
     (State       : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Anchor_Line : Natural)
   is
   begin
      if State.Preview_Visible and then State.Preview_Target_Id /= Editor.Buffers.No_Buffer then
         State.Preview_Anchor := Natural'Max (1, Anchor_Line);
         State.Preview_Scroll := 0;
      end if;
   end Center_Preview_On_Line;

end Editor.Buffer_Switcher.Preview;
