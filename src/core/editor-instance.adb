with Editor.Executor;

package body Editor.Instance is

   ------------------------------------------------------------------------
   procedure Init (E : in out Editor_Instance) is
   begin
      E.Log.Clear;
      E.Position := 0;

      Editor.State.Init (E.State);
   end Init;

   ------------------------------------------------------------------------
   procedure Rebuild (E : in out Editor_Instance) is
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      for I in E.Log.First_Index .. E.Position loop
         Editor.Executor.Execute_No_Log (S, E.Log (I));
      end loop;

      E.State := S;
   end Rebuild;

   ------------------------------------------------------------------------
   procedure Execute
     (E   : in out Editor_Instance;
      Cmd : Editor.Commands.Command) is
   begin
      -- truncate redo branch
      while E.Position < E.Log.Last_Index loop
         E.Log.Delete (E.Log.Last_Index);
      end loop;

      E.Log.Append (Cmd);
      E.Position := E.Log.Last_Index;

      Rebuild (E);
   end Execute;

   ------------------------------------------------------------------------
   procedure Undo (E : in out Editor_Instance) is
   begin
      if E.Position > 0 then
         E.Position := E.Position - 1;
         Rebuild (E);
      end if;
   end Undo;

   ------------------------------------------------------------------------
   procedure Redo (E : in out Editor_Instance) is
   begin
      if E.Position < E.Log.Last_Index then
         E.Position := E.Position + 1;
         Rebuild (E);
      end if;
   end Redo;

end Editor.Instance;