﻿using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class KeybindSettings : MonoBehaviour {
    public KeybindEntry Confirm, Cancel, Menu, Up, Left, Down, Right;
    public Text Listening;
    public Button Save, ResetAll, Restore, Back;

    private Dictionary<string, List<string>> tempKeybinds = new Dictionary<string, List<string>>();

    private CYFTimer textHijackTimer;
    private CYFTimer resetAllTimer;
    private CYFTimer restoreTimer;

    [HideInInspector] public KeybindEntry listening = null;

    void Start() {
        foreach (KeyValuePair<string, List<string>> keybind in KeyboardInput.generalKeys)
            tempKeybinds[keybind.Key] = new List<string>(keybind.Value);

        textHijackTimer = new CYFTimer(3, UpdateListeningText);
        resetAllTimer = new CYFTimer(3, CancelResetAll);
        restoreTimer = new CYFTimer(3, CancelRestore);

        Save.onClick.AddListener(() => {
            if (listening != null)
                StopListening();
            SaveKeybinds();
        });
        ResetAll.onClick.AddListener(() => {
            if (listening != null)
                StopListening();
            if (resetAllTimer.IsElapsing()) {
                resetAllTimer.Stop();
                ResetAll.GetComponentInChildren<Text>().text = "Reset All";
                Reload(true);
            } else {
                resetAllTimer.Start();
                ResetAll.GetComponentInChildren<Text>().text = "You sure?";
            }
        });
        Restore.onClick.AddListener(() => {
            if (listening != null)
                StopListening();
            if (restoreTimer.IsElapsing()) {
                restoreTimer.Stop();
                Restore.GetComponentInChildren<Text>().text = "Restore";
                FactoryResetKeybinds();
            } else {
                restoreTimer.Start();
                Restore.GetComponentInChildren<Text>().text = "You sure?";
            }
        });
        Back.onClick.AddListener(() => {
            if (listening != null)
                StopListening();
            SceneManager.LoadScene("Options");
        });

        Reload();
    }

    public void CancelResetAll() {
        ResetAll.GetComponentInChildren<Text>().text = "Reset All";
    }
    public void CancelRestore() {
        Restore.GetComponentInChildren<Text>().text = "Restore";
    }

    public void LoadKeybinds() {
        KeyboardInput.LoadPlayerKeys();
        tempKeybinds.Clear();
        foreach (KeyValuePair<string, List<string>> keybind in KeyboardInput.generalKeys)
            tempKeybinds[keybind.Key] = new List<string>(keybind.Value);
        foreach (KeybindEntry keybind in new KeybindEntry[] { Confirm, Cancel, Menu, Up, Left, Down, Right })
            UpdateKeyList(keybind);
        UpdateColor();
    }

    public void SaveKeybinds() {
        string invalidReason = null;

        Dictionary<string, string[]> conflicts = KeyboardInput.GetConflicts(tempKeybinds);
        if (conflicts.Count > 0) {
            string[] conflict = conflicts[conflicts.Keys.First()];
            invalidReason = "Please get rid of key conflicts before saving this configuration.";
        }

        if (invalidReason == null)
            foreach (KeyValuePair<string, List<string>> p in tempKeybinds)
                if (p.Value.Count == 0) {
                    invalidReason = "The keybind \"" + p.Key + "\" is unbound! Please add at least one key to it.";
                    break;
                }

        if (invalidReason != null) {
            UnitaleUtil.PlaySound("Reset", "hurtsound");
            HijackListeningText(invalidReason, "ff0000");
            return;
        }

        KeyboardInput.SaveKeybinds(tempKeybinds);
        Reload();

        UnitaleUtil.PlaySound("Save", "saved");
        HijackListeningText("Keybinds saved!");
    }

    public void HijackListeningText(string text, string color = "ffff00") {
        Listening.text = "<color=#" + color + ">" + text + "</color>";
        if (textHijackTimer.IsElapsing())
            textHijackTimer.Stop();
        textHijackTimer.Start();
    }

    public void Reload(bool isReset = false) {
        LoadKeybinds();

        if (isReset) {
            UnitaleUtil.PlaySound("Reset", "hurtsound");
            HijackListeningText("Keybinds reset!");
        }
    }

    public void FactoryResetKeybinds() {
        tempKeybinds.Clear();
        foreach (KeyValuePair<string, List<string>> keybind in KeyboardInput.defaultKeys)
            tempKeybinds[keybind.Key] = new List<string>(keybind.Value);
        foreach (KeybindEntry keybind in new KeybindEntry[] { Confirm, Cancel, Menu, Up, Left, Down, Right })
            UpdateKeyList(keybind);
        UpdateColor();

        UnitaleUtil.PlaySound("Reset", "hurtsound");
        HijackListeningText("Keybinds restored to their default state!");
    }

    public void UpdateColor() {
        List<string> conflictingKeybinds = new List<string>();
        Dictionary<string, string[]> conflicts = KeyboardInput.GetConflicts(tempKeybinds);
        foreach (string[] conflictArray in conflicts.Values)
            foreach (string conflict in conflictArray)
                if (!conflictingKeybinds.Contains(conflict))
                    conflictingKeybinds.Add(conflict);

        foreach (KeybindEntry keybind in new KeybindEntry[] { Confirm, Cancel, Menu, Up, Left, Down, Right }) {
            Color c;
            if (listening != null && listening.Name == keybind.Name)                                     c = new Color(1, 1, 0);
            else if (tempKeybinds[keybind.Name].Count == 0)                                              c = new Color(1, 0, 0);
            else if (conflictingKeybinds.Contains(keybind.Name))                                         c = new Color(1, 0, 0);
            else if (!tempKeybinds[keybind.Name].SequenceEqual(KeyboardInput.generalKeys[keybind.Name])) c = new Color(1, 1, 1);
            else                                                                                         c = new Color(0.7f, 0.7f, 0.7f);
            keybind.SetColor(c);
        }
    }

    public void UpdateKeyList(KeybindEntry keybind) {
        keybind.SetKeyList(string.Join(", ", tempKeybinds[keybind.Name].OrderBy(k => k.Length).ToArray()));
    }

    public void AddKeyToKeybind(KeybindEntry keybind, string key) {
        tempKeybinds[keybind.Name].Add(key);
        UpdateKeyList(keybind);
        UpdateColor();
    }

    public void RemoveKeyFromKeybind(KeybindEntry keybind, string key) {
        tempKeybinds[keybind.Name].Remove(key);
        UpdateKeyList(keybind);
        UpdateColor();
    }

    public void ResetKeybind(KeybindEntry keybind) {
        if (listening != null)
            StopListening();
        tempKeybinds[keybind.Name] = new List<string>(KeyboardInput.generalKeys[keybind.Name]);

        UpdateKeyList(keybind);
        UpdateColor();
    }

    public void ClearKeybind(KeybindEntry keybind) {
        if (listening != null)
            StopListening();

        tempKeybinds[keybind.Name].Clear();

        UpdateKeyList(keybind);
        UpdateColor();
    }

    public void StartListening(KeybindEntry keybind) {
        if (listening != null)
            StopListening();
        listening = keybind;
        listening.SetEditText("Stop");

        UpdateListeningText();
        UpdateColor();
    }

    public void StopListening() {
        if (listening != null)
            listening.SetEditText("Edit");
        listening = null;

        UpdateListeningText();
        UpdateColor();
    }

    public void UpdateListeningText() {
        textHijackTimer.Stop();
        Dictionary<string, string[]> conflicts = KeyboardInput.GetConflicts(tempKeybinds);
        if (listening)
            Listening.text = "Listening for " + listening.Name + ". Press a key to add/remove it! ESC to stop.";
        else if (conflicts.Count == 0)
            Listening.text = "Not currently listening...";
        else {
            string[] conflict = conflicts[conflicts.Keys.First()];
            Listening.text = "Conflict detected: " + conflicts.Keys.First().ToString() + " used for both " + conflict[0] + " and " + conflict[1] + ".";
        }
    }

    void Update() {
        textHijackTimer.Update();
        resetAllTimer.Update();
        restoreTimer.Update();

        if (listening != null) {
            foreach (KeyCode keycode in Enum.GetValues(typeof(KeyCode))) {
                string key = keycode.ToString();
                if (Input.GetKeyDown(keycode)) {
                    if (keycode == KeyCode.Escape)                                           StopListening();
                    else if (tempKeybinds[listening.Name].Contains(key))                     RemoveKeyFromKeybind(listening, key);
                    else if (keycode != KeyCode.Mouse0 && !key.StartsWith("JoystickButton")) AddKeyToKeybind(listening, key);
                }
            }

            foreach (KeyValuePair<string, float> axis in KeyboardInput.axes) {
                string axisName = null;
                float state = Input.GetAxis(axis.Key);
                if (state >= 0.7f && axis.Value < 0.7f)        axisName = axis.Key + " +";
                else if (state <= -0.7f && axis.Value > -0.7f) axisName = axis.Key + " -";

                if (axisName == null)
                    continue;

                if (tempKeybinds[listening.Name].Contains(axisName)) RemoveKeyFromKeybind(listening, axisName);
                else                                                 AddKeyToKeybind(listening, axisName);
            }
        }
    }
}
