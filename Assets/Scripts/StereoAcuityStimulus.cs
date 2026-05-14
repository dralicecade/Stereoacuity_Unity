// StereoAcuityStimulus.cs
// Generates and displays a Random-Dot Stereogram (RDS) stereoacuity stimulus.
//
// The stimulus consists of:
//   • A rectangular field of randomly positioned dots (background + target).
//   • A central square target region whose dots are shifted horizontally by
//     `DisparityPixels` pixels — left-eye image shifted right, right-eye image
//     shifted left (crossed disparity → target appears in front of the screen).
//   • A surrounding background region with zero disparity.
//
// Rendering uses Unity's built-in stereo rendering.  For desktop development
// (non-HMD), side-by-side rendering is produced by two separate cameras
// targeting RenderTextures that are displayed on a full-screen quad.  For an
// HMD build, set UseHMD = true and connect the two cameras to the XR rig's
// left / right eye cameras instead.
//
// Disparity is specified in arcseconds and converted to pixels using the
// current screen / display geometry (ViewingDistanceCm and PixelsPerCm).

using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshRenderer))]
public class StereoAcuityStimulus : MonoBehaviour
{
    // -----------------------------------------------------------------------
    // Inspector fields — display geometry
    // -----------------------------------------------------------------------
    [Header("Display Geometry")]
    [Tooltip("Viewing distance from the observer to the display (centimetres).")]
    [SerializeField] private float viewingDistanceCm = 57.0f;

    [Tooltip("Physical pixel density of the display (pixels per centimetre).")]
    [SerializeField] private float pixelsPerCm = 37.8f;   // ~96 dpi

    // -----------------------------------------------------------------------
    // Inspector fields — stimulus layout
    // -----------------------------------------------------------------------
    [Header("Stimulus Layout")]
    [Tooltip("Width and height of the entire dot field (pixels).")]
    [SerializeField] private int fieldSizePx = 512;

    [Tooltip("Width and height of the disparity target region in the centre (pixels).")]
    [SerializeField] private int targetSizePx = 128;

    [Tooltip("Diameter of each dot (pixels).")]
    [SerializeField] private int dotDiameterPx = 4;

    [Tooltip("Dot density as a fraction of the field area (0–1).")]
    [Range(0.01f, 0.5f)]
    [SerializeField] private float dotDensity = 0.25f;

    [Tooltip("Colour of the dots.")]
    [SerializeField] private Color dotColor = Color.white;

    [Tooltip("Background colour.")]
    [SerializeField] private Color bgColor = Color.black;

    // -----------------------------------------------------------------------
    // Inspector fields — stereo rendering (non-HMD mode)
    // -----------------------------------------------------------------------
    [Header("Stereo Rendering")]
    [SerializeField] private Renderer leftEyeRenderer;
    [SerializeField] private Renderer rightEyeRenderer;

    // -----------------------------------------------------------------------
    // Public read-only state
    // -----------------------------------------------------------------------
    /// <summary>Current disparity of the target region in arcseconds.</summary>
    public float CurrentDisparityArcSec { get; private set; } = 0f;

    // -----------------------------------------------------------------------
    // Private state
    // -----------------------------------------------------------------------
    private Texture2D _leftTex;
    private Texture2D _rightTex;

    private struct Dot { public int X, Y; }
    private List<Dot> _backgroundDots = new List<Dot>();
    private List<Dot> _targetDots     = new List<Dot>();

    // -----------------------------------------------------------------------
    // Unity lifecycle
    // -----------------------------------------------------------------------
    private void Awake()
    {
        _leftTex  = new Texture2D(fieldSizePx, fieldSizePx, TextureFormat.RGBA32, false);
        _rightTex = new Texture2D(fieldSizePx, fieldSizePx, TextureFormat.RGBA32, false);
    }

    private void OnDestroy()
    {
        UnityEngine.Object.Destroy(_leftTex);
        UnityEngine.Object.Destroy(_rightTex);
    }

    // -----------------------------------------------------------------------
    // Public API
    // -----------------------------------------------------------------------

    /// <summary>
    /// Generate and display a new RDS stimulus at the requested disparity.
    /// </summary>
    /// <param name="disparityArcSec">Target disparity in arcseconds.</param>
    public void ShowStimulus(float disparityArcSec)
    {
        CurrentDisparityArcSec = disparityArcSec;
        float disparityPx = ArcSecToPixels(disparityArcSec);

        GenerateDotPositions();
        RenderEye(_leftTex,  disparityPx * +0.5f);
        RenderEye(_rightTex, disparityPx * -0.5f);
        ApplyTextures();
    }

    /// <summary>
    /// Clear the display (blank screen between trials).
    /// </summary>
    public void HideStimulus()
    {
        ClearTexture(_leftTex);
        ClearTexture(_rightTex);
        ApplyTextures();
    }

    // -----------------------------------------------------------------------
    // Conversion helpers
    // -----------------------------------------------------------------------

    /// <summary>Convert arcseconds of disparity to pixels.</summary>
    private float ArcSecToPixels(float arcSec)
    {
        // 1 degree = 60 arcmin = 3600 arcsec
        // tan(θ) ≈ θ (radians) for small angles
        float arcSecInDeg   = arcSec / 3600f;
        float arcSecInRad   = arcSecInDeg * Mathf.Deg2Rad;
        float disparityCm   = 2f * viewingDistanceCm * Mathf.Tan(arcSecInRad / 2f);
        return disparityCm * pixelsPerCm;
    }

    // -----------------------------------------------------------------------
    // Dot generation
    // -----------------------------------------------------------------------
    private void GenerateDotPositions()
    {
        _backgroundDots.Clear();
        _targetDots.Clear();

        int halfField  = fieldSizePx / 2;
        int halfTarget = targetSizePx / 2;

        // Target region bounding box (centred in the field)
        int tx0 = halfField - halfTarget;
        int tx1 = halfField + halfTarget;
        int ty0 = halfField - halfTarget;
        int ty1 = halfField + halfTarget;

        int totalPixels = fieldSizePx * fieldSizePx;
        int dotArea     = dotDiameterPx * dotDiameterPx;
        int numDots     = Mathf.Max(1, Mathf.RoundToInt(totalPixels * dotDensity / dotArea));

        for (int i = 0; i < numDots; i++)
        {
            int x = Random.Range(0, fieldSizePx);
            int y = Random.Range(0, fieldSizePx);

            bool inTarget = (x >= tx0 && x < tx1 && y >= ty0 && y < ty1);
            if (inTarget)
                _targetDots.Add(new Dot { X = x, Y = y });
            else
                _backgroundDots.Add(new Dot { X = x, Y = y });
        }
    }

    // -----------------------------------------------------------------------
    // Rendering
    // -----------------------------------------------------------------------

    /// <summary>
    /// Render one eye's texture.  Target dots are shifted by
    /// <paramref name="targetShiftPx"/> pixels horizontally; background dots
    /// are drawn without shift.
    /// </summary>
    private void RenderEye(Texture2D tex, float targetShiftPx)
    {
        ClearTexture(tex);

        int shiftInt = Mathf.RoundToInt(targetShiftPx);

        // Background dots (no shift)
        foreach (var dot in _backgroundDots)
            DrawDot(tex, dot.X, dot.Y, 0);

        // Target dots (shifted)
        foreach (var dot in _targetDots)
            DrawDot(tex, dot.X, dot.Y, shiftInt);

        tex.Apply();
    }

    private void DrawDot(Texture2D tex, int cx, int cy, int xShift)
    {
        int radius = dotDiameterPx / 2;
        int startX = cx - radius + xShift;
        int startY = cy - radius;

        for (int dx = 0; dx < dotDiameterPx; dx++)
        for (int dy = 0; dy < dotDiameterPx; dy++)
        {
            int px = startX + dx;
            int py = startY + dy;
            if (px >= 0 && px < fieldSizePx && py >= 0 && py < fieldSizePx)
                tex.SetPixel(px, py, dotColor);
        }
    }

    private void ClearTexture(Texture2D tex)
    {
        Color[] fill = new Color[fieldSizePx * fieldSizePx];
        for (int i = 0; i < fill.Length; i++) fill[i] = bgColor;
        tex.SetPixels(fill);
        tex.Apply();
    }

    private void ApplyTextures()
    {
        if (leftEyeRenderer  != null) leftEyeRenderer.material.mainTexture  = _leftTex;
        if (rightEyeRenderer != null) rightEyeRenderer.material.mainTexture = _rightTex;
    }
}
