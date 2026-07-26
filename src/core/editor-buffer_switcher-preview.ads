with Editor.Buffer_Types;

package Editor.Buffer_Switcher.Preview is

   procedure Show_Preview
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Hide_Preview
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Toggle_Preview
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   function Has_Preview
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   procedure Set_Preview_Target
     (State       : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Target      : Editor.Buffer_Types.Buffer_Id;
      Anchor_Line : Natural);

   procedure Clear_Preview_Target
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   function Preview_Target
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State)
      return Editor.Buffer_Types.Buffer_Id;

   function Preview_Anchor_Line
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Natural;

   function Preview_Scroll_Offset
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Natural;

   procedure Scroll_Preview_Next_Line
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Scroll_Preview_Previous_Line
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Center_Preview_On_Line
     (State       : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Anchor_Line : Natural);

end Editor.Buffer_Switcher.Preview;
