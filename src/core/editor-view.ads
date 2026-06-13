with Editor.Layout;
with Editor.Render_Model;
with Editor.View_Types;
with Editor.Wrap;

package Editor.View is

   subtype View_State is Editor.View_Types.View_State;

   function Snapshot return View_State;

   procedure Restore
     (State : View_State;
      Snap_Visual_To_Target : Boolean := True);

   ------------------------------------------------------------------
   -- Reset all transient view state
   ------------------------------------------------------------------
   procedure Reset;

   procedure Reset_Scroll;

   ------------------------------------------------------------------
   -- Viewport size
   ------------------------------------------------------------------
   procedure Set_Viewport
     (Width  : Natural;
      Height : Natural);

   function Viewport_Width return Natural;
   function Viewport_Height return Natural;

   ------------------------------------------------------------------
   -- Time / animation tick
   ------------------------------------------------------------------
   function Current_Time_Seconds return Duration;
   procedure Set_Time_Seconds (Now : Duration);

   --  Advance view-owned animation state.  Logical scroll positions remain
   --  authoritative; this procedure only moves the visual scroll offsets
   --  toward those logical targets and updates future view animations.
   procedure Tick (Delta_Time_Sec : Float);

   function Caret_Visible return Boolean;

   ------------------------------------------------------------------
   -- Scroll management
   ------------------------------------------------------------------
   procedure Update_Scroll_For_Snapshot
     (Snap   : Editor.Render_Model.Render_Snapshot;
      Layout : Editor.Layout.Layout_Config);

   function Scroll_X return Natural;
   function Scroll_Y return Natural;

   function Visual_Scroll_X return Float;
   function Visual_Scroll_Y return Float;

   --  Convert a visible row or document column to render-space coordinates
   --  using the interpolated visual scroll offset while preserving the
   --  logical viewport row/column model.
   function Visual_Screen_X
     (Layout     : Editor.Layout.Layout_Config;
      Line_Count : Natural;
      Col        : Natural) return Float;

   function Visual_Screen_Y
     (Layout      : Editor.Layout.Layout_Config;
      Visible_Row : Natural) return Float;

   procedure Set_Scroll (X, Y : Natural);

   procedure Set_Scroll_Y_Clamped
     (Row_Count      : Natural;
      Viewport_Rows  : Natural;
      Desired_Scroll : Natural);

   procedure Set_Scroll_X_Clamped
     (Column_Count   : Natural;
      Viewport_Cols  : Natural;
      Desired_Scroll : Natural);

   --  Clear a user-directed vertical scroll override.  Minimap navigation uses
   --  Set_Scroll_Y_Clamped to place the viewport independently of the caret;
   --  the next ordinary editing/navigation command should re-enable normal
   --  caret-following scroll behaviour.
   procedure Clear_User_Scroll_Override;

   procedure Set_Wrap_Mode (Mode : Editor.Wrap.Wrap_Mode);
   function Wrap_Mode return Editor.Wrap.Wrap_Mode;

   procedure Auto_Scroll_For_Point
     (X      : Natural;
      Y      : Natural;
      Layout : Editor.Layout.Layout_Config);

end Editor.View;