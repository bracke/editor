with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Recent_Buffers;

package body Editor.Recent_Buffers.Tests is

   overriding function Name
     (T : Recent_Buffers_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Recent_Buffers");
   end Name;

   procedure Test_Order_Deduplicates_And_Removes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Recent_Buffers.Recent_Buffer_State;
   begin
      Assert (Editor.Recent_Buffers.Count (State) = 0,
              "recent-buffer order must start empty");

      Editor.Recent_Buffers.Mark_Activated (State, 1);
      Editor.Recent_Buffers.Mark_Activated (State, 2);
      Assert (Editor.Recent_Buffers.Count (State) = 2,
              "two opened buffers must be tracked once each");
      Assert (Editor.Recent_Buffers.Id_At (State, 1) = 2,
              "latest activated buffer must be most recent");
      Assert (Editor.Recent_Buffers.Id_At (State, 2) = 1,
              "previously activated buffer must be second");

      Editor.Recent_Buffers.Mark_Activated (State, 1);
      Assert (Editor.Recent_Buffers.Count (State) = 2,
              "reactivating a buffer must not duplicate it");
      Assert (Editor.Recent_Buffers.Id_At (State, 1) = 1,
              "reactivated buffer must move to the front");

      Editor.Recent_Buffers.Remove (State, 1);
      Assert (Editor.Recent_Buffers.Count (State) = 1,
              "closing a buffer must remove it from recent order");
      Assert (not Editor.Recent_Buffers.Contains (State, 1),
              "removed buffer must not remain in recent order");
   end Test_Order_Deduplicates_And_Removes;

   procedure Test_Previous_Next_Traversal_Wraps
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State  : Editor.Recent_Buffers.Recent_Buffer_State;
      Target : Editor.Recent_Buffers.Buffer_Key;
   begin
      Editor.Recent_Buffers.Mark_Activated (State, 1);
      Editor.Recent_Buffers.Mark_Activated (State, 2);
      Editor.Recent_Buffers.Mark_Activated (State, 3);

      Target := Editor.Recent_Buffers.Previous_Target (State, 3);
      Assert (Target = 2,
              "previous recent buffer must choose most recent non-active target");
      Editor.Recent_Buffers.Mark_Activated (State, Target, Preserve_Traversal => True);

      Target := Editor.Recent_Buffers.Previous_Target (State, 2);
      Assert (Target = 1,
              "previous recent buffer must walk backward through MRU order");
      Editor.Recent_Buffers.Mark_Activated (State, Target, Preserve_Traversal => True);

      Target := Editor.Recent_Buffers.Previous_Target (State, 1);
      Assert (Target = 3,
              "previous recent traversal must wrap deterministically");
      Editor.Recent_Buffers.Mark_Activated (State, Target, Preserve_Traversal => True);

      Target := Editor.Recent_Buffers.Next_Target (State);
      Assert (Target = 1,
              "next recent buffer must reverse the previous traversal sequence");
   end Test_Previous_Next_Traversal_Wraps;

   procedure Test_Explicit_Activation_Clears_Forward_Traversal
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State  : Editor.Recent_Buffers.Recent_Buffer_State;
      Target : Editor.Recent_Buffers.Buffer_Key;
   begin
      Editor.Recent_Buffers.Mark_Activated (State, 1);
      Editor.Recent_Buffers.Mark_Activated (State, 2);

      Target := Editor.Recent_Buffers.Previous_Target (State, 2);
      Assert (Target = 1,
              "test setup must create a previous recent target");
      Assert (Editor.Recent_Buffers.Has_Next (State),
              "previous traversal must create a forward traversal opportunity");

      Editor.Recent_Buffers.Mark_Activated (State, 2);
      Assert (not Editor.Recent_Buffers.Has_Next (State),
              "explicit non-recent activation must clear forward traversal");
   end Test_Explicit_Activation_Clears_Forward_Traversal;

   overriding procedure Register_Tests
     (T : in out Recent_Buffers_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Order_Deduplicates_And_Removes'Access,
         "order deduplicates and removes closed buffers");
      Register_Routine
        (T, Test_Previous_Next_Traversal_Wraps'Access,
         "previous next traversal wraps through MRU order");
      Register_Routine
        (T, Test_Explicit_Activation_Clears_Forward_Traversal'Access,
         "explicit activation clears traversal cursor");
   end Register_Tests;

end Editor.Recent_Buffers.Tests;
